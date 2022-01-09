//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITournament} from "../interfaces/ITournament.sol";
import {IVault} from "../interfaces/IVault.sol";

contract Tournament is  ITournament, ERC721URIStorage, Pausable, AccessControl {

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
    Vault public prizeVault;

    Counters.Counter _prizeIds;
    Counters.Counter _adminCounter;

    bool private _isPrivate;

    constructor(
        string memory _URI,
        address _token,
        uint256 _start,
        address _admin
    ) ERC721("Jinushi", "JNSHI") ERC721URIStorage() {
        if (_fee > 0) {
            _registrationFee = _fee;
            registrationVault = new Vault(_token, address(this));
        }
        prizeVault = new Vault(_token, address(this));

        _tournamentURI = _URI;
        _rewardToken = _token;
        _startTime = _start;
        _registrationClosingTime = _registrationClosesAt;

        _isPrivate = true;

        _setupRole(DEFAULT_ADMIN_ROLE, _admin);
    }

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAdmin(_newAdmin);}

    function addPlayer(address _player) external onlyRole(PLAYER) {
        _addPlayer(_player);}

    function _addAdmin(address _newAdmin) private {
        grantRole(ADMIN, _newAdmin);}

    function _addPlayer(
        int8 _index,
        uint8 position,
        uint8[] memory propertyOwned,
        uint256 balance,
        address player
    ) private {
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


    function movePlayer(uint8 _byDice, uint8 _playerId) external
    {
        Player playerInstance = players[_playerId];
        grantRole(ACTIVE_TURN, playerInstance.playerAddress);
        playerInstance.position = (playerInstance.position + _byDice) % 24;
        _playerMove.increment();
        emit PlayerMoved(player, _byDice);
    }

    function buildHouses(uint8 _propertyIndex, uint8 _numberOfHouses) external onlyRole(ACTIVE_TURN) {
        require(msg.sender == Property[_propertyIndex].owner);
        for(uint8 i = 0; i < _numberOfHouses; i++) {
            _buildHouse(_propertyIndex);
        }
    }

    function goToJail(uint8 _playerId) external onlyRole(BANKER) {
        Player playerInstance = players[_playerId];
        grantRole(JAILED_USER, playerInstance.playerAddress);
        playerInstance.position = 10;
        emit PlayerMoved(player, 10); 
    }

    function _buildHouse(uint8 _propertyIndex) private {
        require(properties[_propertyIndex].owner.balance > properties[_propertyIndex].houseCost);
        properties[_propertyIndex].owner.balance -= properties[_propertyIndex].houseCost;
    }


}