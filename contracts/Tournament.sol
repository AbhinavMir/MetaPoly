//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITournament} from "../interfaces/ITournament.sol";
import {IVault} from "../interfaces/IVault.sol";

contract Tournament is  ITournament, ERC721URIStorage, Pausable, AccessControl, IVault {

    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    Counters.Counter private _playerIdCounter;
    Counters.Counter private _playerMoveCounter; // Decides who has to move
    
    bytes32 public constant ACTIVE_TURN = keccak256("ACTIVE_TURN"); // User who has to move
    bytes32 public constant JAILED_USER = keccak256("JAILED_USER");
    bytes32 public constant BLACKLISTED_USER = keccak256("BLACKLISTED_USER");
    bytes32 public constant ADMIN = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PLAYER = keccak256("PLAYER");
    bytes32 public constant BANKER = keccak256("BANKER");

    string private _tournamentURI;
    bool terminated;

    Player[] public players;
    mapping(address => Player) public playerByAddress;

    Property[] public properties;

    address private _rewardToken;
    uint8 private _PrizeMoneyTracker;
    uint256 private _registrationFee;

    uint256 private _startTime;

    Vault public registrationVault;

    Counters.Counter _prizeIds;
    Counters.Counter _adminCounter;

    bool private _isPrivate;

    constructor(
        string memory _URI,
        address _token,
        uint _fee, // Should be able to modify
        uint256 _start,
        address _admin,
        bool _isPrivate
    ) ERC721("Jinushi", "JNSHI") ERC721URIStorage() {
        if (_fee > 0) {
            _registrationFee = _fee; 
            registrationVault = new Vault(_token, address(this));
        }

        _tournamentURI = _URI;
        _rewardToken = _token;
        _startTime = _start;
        _isPrivate = _isPrivate;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAdmin(_newAdmin);}

    function addPlayer(address _player) external onlyRole(PLAYER) {
        _addPlayer(_player);}

    
    function forfeit(uint8 _playerId) external onlyRole(PLAYER) {
        _player = playerByAddress[_playerId];
        require(_player == msg.sender);
        _removePlayer(_player);
    }

    function _removePlayer(uint8 _playerId) internal onlyRole(PLAYER)
    {
        delete players[_playerId];
        _playerIdCounter.decrement();
    }

    function movePlayer(uint8 _byDice, uint8 _playerId) external
    {
        Player playerInstance = players[_playerId];
        playerInstance.position = (playerInstance.position + _byDice) % 24;
        grantRole(ACTIVE_TURN, playerInstance.playerAddress);
        emit playerMoved(player, _byDice, playerInstance.position);
    }

    function endTurn(uint8 _playerId) external onlyRole(ACTIVE_TURN) {
        Player playerInstance = players[_playerId];
        revokeRole(ACTIVE_TURN, playerInstance.playerAddress);
        _playerMoveCounter.increment();
        emit turnEnded(_playerId, _playerMoveCounter.current());
    }

    function buildHouses(uint8 _propertyIndex, uint8 _numberOfHouses) external onlyRole(ACTIVE_TURN) {
        require(msg.sender == Property[_propertyIndex].owner, "You are not the owner of this property");
        for(uint8 i = 0; i < _numberOfHouses; i++) {
            _buildHouse(_propertyIndex);
        }
    }

    function goToJail(uint8 _playerId) external onlyRole(BANKER) {
        Player playerInstance = players[_playerId];
        grantRole(JAILED_USER, playerInstance.playerAddress);
        playerInstance.position = 10;
        emit playerJailed(_playerId);
    }

    function payRent(uint8 _playerId, uint8 _propertyIndex) external onlyRole(ACTIVE_TURN) {
        Player playerInstance = players[_playerId]; // instantiate player instance
        Player ownerInstance = players[Property[_propertyIndex].owner._index]; // instantiate current owner
        Property propertyInstance = properties[_propertyIndex]; // instantiate property instance
        uint rent = propertyInstance.baseRent + (propertyInstance.houseRent * propertyInstance.houseCounter);
        
        // Check if player has enough money or net worth to pay rent
        if(playerInstance.balance >= propertyInstance.rent){
            if(playerInstance.netWorth >= propertyInstance.rent){
                playerInstance.balance -= rent;
                propertyInstance.owner.balance += rent;
                emit playerPaidRent(_playerId, _propertyIndex, propertyInstance.rent);
            } else {
                forfeit(_playerId);
                emit playerForfeited(_playerId);
                emit playerPaidRent(_playerId, _propertyIndex, propertyInstance.rent);
                playerInstance.balance -= propertyInstance.rent;
                propertyInstance.owner.balance += propertyInstance.rent;
            }
        }
        playerInstance.balance -= propertyInstance.rent;
        propertyInstance.owner.balance += propertyInstance.rent;
        emit playerPaidRent(_playerId, ownerInstance._index , rent);
    }

    function buyProperty(uint8 _propertyIndex, uint8 _playerId) external onlyRole(ACTIVE_TURN) {
        require(properties[_propertyIndex].isOwned == false, "Property is already owned");
        Player playerInstance = players[_playerId];
        require(playerInstance.balance > properties[_propertyIndex].price, "Player does not have enough money");
        playerInstance.balance -= properties[_propertyIndex].price;
    }

    function sellProperty(uint8 _propertyIndex, uint8 _playerId) external onlyRole(ACTIVE_TURN) {
        require(properties[_propertyIndex].isOwned == true, "Property is not owned");
        Player playerInstance = players[_playerId];
        playerInstance.balance += properties[_propertyIndex].price;
    }

    function getPlayerBalance(uint8 _playerId) external view returns (uint256) {
        return players[_playerId].balance;
    }

    function getPlayerPosition(uint8 _playerId) external view returns (uint8) {
        return players[_playerId].position;
    }

    function getPlayerProperty(uint8 _playerId) external view returns (uint8[]) {
        return players[_playerId].propertyOwned;
    }

    function getPlayerPropertyCount(uint8 _playerId) external view returns (uint8) {
        return players[_playerId].propertyOwned.length;
    }

    function getPlayerNetworth(uint8 _playerId) external view returns (uint256) {}

    /* 
    Internal Functions
    */

    function _addAdmin(address _newAdmin) internal {
        grantRole(ADMIN, _newAdmin);}

    function _addPlayer(
        int8 _index,
        uint8 position,
        uint8[] memory propertyOwned,
        uint256 balance,
        address player
    ) internal {
        _index = _playerIdCounter.current();

        grantRole(PLAYER, _player);
        _newPlayer = new Player(
            _index,
            position,
            propertyOwned,
            balance,
            player
        );
        
        players.push(_newPlayer);
        _playerIdCounter.increment();

        emit PlayerAdded(_newPlayer);
    }

    function _buildHouse(uint8 _propertyIndex) internal {
        require(properties[_propertyIndex].owner.balance > properties[_propertyIndex].houseCost, "Not enough funds");
        properties[_propertyIndex].owner.balance = properties[_propertyIndex].owner.balance - properties[_propertyIndex].houseCost;

    }
}