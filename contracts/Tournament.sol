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
    bytes32 public constant BLOCKED_USER = keccak256("BLOCKED_USER");
    // bytes32 public constant BLACKLISTED_USER = keccak256("BLACKLISTED_USER");
    bytes32 public constant ADMIN = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PLAYER = keccak256("PLAYER");
    bytes32 public constant BANKER = keccak256("BANKER");

    mapping(address => Player) public playerByAddress;
    // uint8[] public players;

    mapping(uint8 => Property) public properties;

    // address private _rewardToken;
    // uint256 private _registrationFee;

    uint256 private _startTime;

    // Vault public registrationVault;

    Counters.Counter _prizeIds;
    Counters.Counter _adminCounter;

    // bool private _isPrivate;

    constructor(
        string memory _URI,
        uint _fee,
        address _admin
     ) {}
    

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAdmin(_newAdmin);}

    function addPlayer(address _player) external onlyRole(PLAYER) {
        _addPlayer(_player);}

    function forfeit(address _player) external onlyRole(PLAYER) {
        require(_player == msg.sender, "Only player can forfeit");
        _removePlayer(_player);
    }

    function _removePlayer(address _playerAddress) internal 
    {
        delete playerByAddress[_playerAddress];
        _playerIdCounter.decrement();
    }

    function movePlayer(uint8 _numberDice, address _playerAddress) external onlyPlayer(_playerAddress) {
        playerByAddress[_playerAddress].position = (playerByAddress.position + _numberDice) % 24;
        grantRole(ACTIVE_TURN, playerByAddress[_playerAddress].playerAddress);
        // // emit playerMoved(_numberDice, msg.sender);
    }

    function endTurn(address _playerAddress) external onlyRole(ACTIVE_TURN) {
        revokeRole(ACTIVE_TURN, msg.sender);
        grantRole(PLAYER, msg.sender);
        _playerMoveCounter.increment();
        // emit turnEnded(_playerMoveCounter.current(), msg.sender);
    }

    function buildHouses(uint8 _propertyIndex, uint8 _numberOfHouses) external onlyRole(ACTIVE_TURN) {
        require(msg.sender == Property[_propertyIndex].owner, "You are not the owner of this property");
        for(uint8 i = 0; i < _numberOfHouses; i++) {
            _buildHouse(_propertyIndex);
        }
    }

    function goToJail(address _player) external onlyRole(BANKER) {
        grantRole(BLOCKED_USER, playerByAddress[_player].playerAddress);
        playerByAddress[_player].position = 10;
        // emit playerJailed(_playerId);
    }

    function payRent(uint8 _propertyIndex) external onlyPlayer
    {
        require(Property[_propertyIndex].owner != msg.sender, "You are the owner of this property");
        uint256 _rent = Property[_propertyIndex].baseRent;
        uint8 _houseCounter = Property[_propertyIndex].houseCounter;
        uint8 _houseRent = Property[_propertyIndex].houseRent;
        address _houseOwner = Property[_propertyIndex].owner;

        if(Property[_propertyIndex].isMortgaged) {
            _rent = 0;
        }

        else if(Property[_propertyIndex].houseCounter > 0) {
            _rent = _rent + (_houseCounter * _rent);
        }

        else{
            _rent = _rent;
        }

        _pay(_rent, _houseOwner, msg.sender);
    }

    function _pay(uint256 _amount, address _to, address _from) internal 
    {
        require(_amount > 0, "Amount must be greater than 0");
        require(_to != _from, "Cannot pay to yourself");
        require(msg.sender == _from, "Only the sender can pay");
        require(msg.sender != _to, "Cannot pay to yourself");
        require(msg.sender == playerByAddress[_from].playerAddress, "Only the sender can pay");
        require(playerByAddress[_from].balance >= _amount, "Not enough balance");
        playerByAddress[_from].balance = playerByAddress[_from].balance - _amount;
        playerByAddress[_to].balance = playerByAddress[_to].balance + _amount;
        emit paid(_amount, _to, _from);
    }

    function _transferProperty(address _to, uint8 _propertyIndex) internal {
        require(Property[_propertyIndex].owner == msg.sender, "You are not the owner of this property");
        Property[_propertyIndex].owner = _to;
        // emit propertyTransferred(_to, _propertyIndex);
    }

    function buyProperty(uint8 _propertyIndex, uint8 _playerId) external onlyPlayer
    {
        /*
        bytes32 name;
        uint8 price;
        uint8 position;
        uint8 baseRent;
        uint8 houseCounter;
        uint8 houseCost;
        uint8 houseRent;
        bool mortgaged;
        bool owned;
        Player owner;
        */

        require(properties[_propertyIndex].owned == false, "Property is already owned");
        require(properties[_propertyIndex].owner != msg.sender, "You are the owner of this property");
        require(playerByAddress[msg.sender].balance >= properties[_propertyIndex].price, "You don't have enough money");
        properties[_propertyIndex].owned = true;
        properties[_propertyIndex].owner = msg.sender;
        playerByAddress[msg.sender].balance -= properties[_propertyIndex].price;
        playerByAddress[msg.sender].properties.push(_propertyIndex);
        // emit propertyBought(_propertyIndex, msg.sender);
    }

    function sellProperty(uint8 _propertyIndex, uint8 _playerId) external onlyRole(ACTIVE_TURN) {
        require(properties[_propertyIndex].owner == msg.sender, "You are not the owner of this property");
        require(properties[_propertyIndex].owned == true, "Property is not owned");
        require(properties[_propertyIndex].mortgaged == false, "Property is mortgaged");
        require(properties[_propertyIndex].houseCounter == 0, "Property has houses");
        require(properties[_propertyIndex].houseCost == 0, "Property has houses");
        require(properties[_propertyIndex].houseRent == 0, "Property has houses");
        require(properties[_propertyIndex].baseRent == 0, "Property has houses");
        require(properties[_propertyIndex].price == 0, "Property has houses");
        properties[_propertyIndex].owned = false;
        properties[_propertyIndex].owner = 0;
        playerByAddress[msg.sender].balance += (properties[_propertyIndex].price)/2;
        playerByAddress[msg.sender].properties.remove(_propertyIndex);
        // emit propertySold(_propertyIndex, msg.sender);
    }

    function getPlayerNetworth(address _player) external view returns (uint256) 
    {
        uint256 oldNetWorth = playerByAddress[_player].netWorth;
        uint256 newNetWorth = 0;
        for(uint8 i = 0; i < playerByAddress[_player].propertyOwned.length; i++) {
            newNetWorth += (properties[playerByAddress[_player].propertyOwned[i]].price)/2;
        }

        newNetWorth += playerByAddress[_player].balance;
        return newNetWorth;
    }

    function finePlayer(uint8 _playerId, uint256 amount) external onlyPlayer(_playerId) {
        require(playerByAddress[_playerId].balance >= amount, "You don't have enough money");
        playerByAddress[_playerId].balance -= amount;
        // emit playerPaidIncomeTax(_playerId);
    }

    function _addAdmin(address _newAdmin) internal {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);}

    function _addPlayer(address _playerAddress) internal {
        require(playerByAddress[_playerAddress] == false, "Player already exists");
        playerByAddress[_playerAddress] = Player(_playerAddress);
        playerByAddress[_playerAddress].playerId = _playerIdCounter.increment();
        playerByAddress[_playerAddress].balance = 1500;
    }
    
    function _buildHouse(uint8 _propertyIndex) internal {
        require(properties[_propertyIndex].owner.balance > properties[_propertyIndex].houseCost, "Not enough funds");
        properties[_propertyIndex].owner.balance = properties[_propertyIndex].owner.balance - properties[_propertyIndex].houseCost;
    }

    function _destroyHouse(uint8 _propertyIndex) internal {
        require(properties[_propertyIndex].owner.balance > properties[_propertyIndex].houseCost, "Not enough funds");
        properties[_propertyIndex].owner.balance = properties[_propertyIndex].owner.balance - properties[_propertyIndex].houseCost;
    }

    function _isActive(address user) internal view returns (bool) {
        require(Player[user]._isActive == false, "User is not active");
        return true;
    }

    modifier onlyPlayer(address _playerAddress)
    {
        require(msg.sender == _playerAddress, "Not Player");
        require(_isActive(msg.sender), "Inactive User");
        _;
    }
}