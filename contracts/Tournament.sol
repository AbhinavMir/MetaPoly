//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.11;

import {ERC721URIStorage, ERC721} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {Counters} from "@openzeppelin/contracts/utils/Counters.sol";
import {Pausable} from "@openzeppelin/contracts/security/Pausable.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {ITournament} from "../interfaces/ITournament.sol";
import "../interfaces/ITournament.sol";
import "../interfaces/ITournament.sol";
import "../interfaces/ITournament.sol";

contract Tournament is ITournament, ERC721URIStorage, Pausable, AccessControl {
    using Counters for Counters.Counter;
    using SafeERC20 for IERC20;
    IERC20 public immutable token;
    Counters.Counter private _playerIdCounter;
    Counters.Counter private _playerMoveCounter; // Decides who has to move

    string public baseURI;

    /*
     *   Roles for the tournament
     */
    bytes32 public constant ACTIVE_PLAYER = keccak256("ACTIVE_PLAYER");
    // bytes32 public constant BLACKLISTED_USER = keccak256("BLACKLISTED_USER");
    bytes32 public constant ADMIN = keccak256("DEFAULT_ADMIN_ROLE");
    bytes32 public constant PLAYER = keccak256("PLAYER");
    bytes32 public constant BANKER = keccak256("BANKER");
    bytes32 public constant JAILED_USER = keccak256("JAILED_USER");

    /*
     * Mapping variables for address->Player struct, and for propertyId->Property struct - can also use arrays
     */
    mapping(address => Player) public playerByAddress;
    mapping(uint256 => address) public moveCounterFromPlayerIdToAddress;
    Property[] public properties;

    /*
     * Metadata variables for the tournament
     */
    uint256 MAX_CELLS;
    uint256 private startTime;
    uint256 private TTL;
    uint256 private maxPlayers;
    uint256 private registrationFee;
    uint256 private startingAmount;
    bool isActive;
    bool isPaused;
    bool hasStarted;
    Counters.Counter private _adminCounter;

    constructor(
        string memory _baseURI,
        uint256 _registrationFee,
        uint256 _startTime,
        uint256 _TTL,
        uint256 _maxPlayers,
        string[] memory _propertyNames,
        uint256[] memory _propertyPrices,
        uint256 _maxCells
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        baseURI = _baseURI;
        playerByAddress = _players;
        startTime = _startTime;
        TTL = _TTL;
        maxPlayers = _maxPlayers;
        MAX_CELLS = _maxCells;
        registrationFee = _registrationFee;
        for (uint8 i = 0; i < _propertyNames.length; i++) {
            properties.push(
                Property(
                    _propertyNames[i],
                    _propertyPrices[i],
                    0,
                    address(0),
                    0
                )
            );
        }
    }

    function nextPlayer() internal {
        _playerMoveCounter.increment();
    }

    function joinTournament() external {
        require(_playerIdCounter.current() < maxPlayers, "Tournament is full");
        require(
            block.timestamp < startTime + TTL,
            "Tournament has already started"
        );
        require(
            playerByAddress[msg.sender].playerAddress == address(0),
            "Player already joined"
        );
        require(
            token.balanceOf(msg.sender) >= registrationFee,
            "Not enough tokens to join"
        );
        require(hasStarted == false, "Tournament has already started");
        token.safeTransferFrom(msg.sender, address(this), registrationFee);
        _addPlayer(msg.sender);
        _playerIdCounter.increment();
        emit playerJoined(_playerIdCounter.current(), msg.sender);
    }

    function addAdmin(address _newAdmin) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _addAdmin(_newAdmin);
    }

    function forfeit(address _player) external onlyRole(PLAYER) {
        require(_player == msg.sender, "Only player can forfeit");
        require(
            playerByAddress[_player].playerAddress == msg.sender,
            "Player not found"
        );
        _removePlayer(_player);
        emit playerForfeited(_playerId);
    }

    function _removePlayer(address _playerAddress) internal {
        if(hasRole(ACTIVE_PLAYER, _playerAddress)) {
            _removeRole(ACTIVE_PLAYER, _playerAddress);
        }
        revokeRole(PLAYER, _playerAddress);
        playerByAddress[_playerAddress]._isActive = false;
        _playerIdCounter.decrement();
    }

    function movePlayer(uint8 _numberDice, address _playerAddress)
        external
        activePlayer(_playerAddress)
    {
        playerByAddress[_playerAddress].position =
            (playerByAddress.position + _numberDice) %
            MAX_CELLS;
        grantRole(ACTIVE_TURN, playerByAddress[_playerAddress].playerAddress);
        emit playerMoved(_numberDice, _playerAddress, playerByAddress.position);
    }

    function endTurn(address _playerAddress)
        external
        activePlayer(_playerAddress)
    {
        revokeRole(ACTIVE_TURN, msg.sender);
        grantRole(PLAYER, msg.sender);
        _playerMoveCounter.increment();
        emit turnEnded(_playerMoveCounter.current(), msg.sender);
    }

    function buildHouses(uint8 _propertyIndex, uint8 _numberOfHouses)
        external
        activePlayer(msg.sender)
    {
        require(
            msg.sender == Property[_propertyIndex].owner.playerAddress,
            "You are not the owner of this property"
        );
        for (uint8 i = 0; i < _numberOfHouses; i++) {
            _buildHouse(_propertyIndex);
        }
    }

    function goToJail(address _player) external onlyRole(BANKER) {
        grantRole(JAILED_USER, playerByAddress[_player].playerAddress);
        playerByAddress[_player].position = 10;
        emit playerJailed(_playerId);
    }

    function payRent(uint8 _propertyIndex) external onlyPlayer {
        require(
            Property[_propertyIndex].owner != msg.sender,
            "You are the owner of this property"
        );
        uint256 _rent = Property[_propertyIndex].baseRent;
        uint8 _houseCounter = Property[_propertyIndex].houseCounter;
        uint8 _houseRent = Property[_propertyIndex].houseRent;
        address _houseOwner = Property[_propertyIndex].owner;

        if (Property[_propertyIndex].isMortgaged) {
            _rent = 0;
        } else if (Property[_propertyIndex].houseCounter > 0) {
            _rent = _rent + (_houseCounter * _rent);
        } else {
            _rent = _rent;
        }

        _pay(_rent, _houseOwner, msg.sender);
    }

    function _pay(
        uint256 _amount,
        address _to,
        address _from
    ) internal {
        require(_amount > 0, "Amount must be greater than 0");
        require(_to != _from, "Cannot pay to yourself");
        require(msg.sender == _from, "Only the sender can pay");
        require(msg.sender != _to, "Cannot pay to yourself");
        require(
            msg.sender == playerByAddress[_from].playerAddress,
            "Only the sender can pay"
        );
        require(
            playerByAddress[_from].balance >= _amount,
            "Not enough balance"
        );
        playerByAddress[_from].balance =
            playerByAddress[_from].balance -
            _amount;
        playerByAddress[_to].balance = playerByAddress[_to].balance + _amount;
        emit paid(_amount, _to, _from);
    }

    function _transferProperty(address _to, uint8 _propertyIndex) internal {
        require(
            Property[_propertyIndex].owner == msg.sender,
            "You are not the owner of this property"
        );
        playerByAddress[_to].properties.push(_propertyIndex);
        Player newOwner = playerByAddress[_to];
        Property[_propertyIndex].owner = newOwner;
        emit propertyTransferred(_to, _propertyIndex);
    }

    function buyProperty(uint8 _propertyIndex, uint8 _playerId, address _player)
        external
        activePlayer(_player)
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

        require(
            properties[_propertyIndex].isOwned == false,
            "Property is already owned"
        );
        require(
            playerByAddress[_player].balance >=
                properties[_propertyIndex].price,
            "You don't have enough money"
        );
        properties[_propertyIndex].isOwned = true;
        properties[_propertyIndex].owner = playerByAddress[_player];
        playerByAddress[_player].balance -= properties[_propertyIndex].price;
        playerByAddress[_player].propertyOwned.push(_propertyIndex);
        emit propertyBought(_propertyIndex, msg.sender);
    }

    function sellProperty(uint8 _propertyIndex, uint8 _playerId)
        external
    {
        require(
            properties[_propertyIndex].owner.playerAddress == msg.sender,
            "You are not the owner of this property"
        );
        require(
            properties[_propertyIndex].isOwned == true,
            "Property is not owned by anyone"
        );
        require(
            properties[_propertyIndex].isMortgaged == false,
            "Property is mortgaged"
        );
        require(
            properties[_propertyIndex].houseCounter == 0,
            "Property has houses"
        );
        properties[_propertyIndex].isOwned = false;
        playerByAddress[msg.sender].balance +=
            (properties[_propertyIndex].price) /
            2;
        playerByAddress[msg.sender].properties.remove(_propertyIndex);
        emit propertySold(_propertyIndex, msg.sender);
    }

    function getPlayerNetworth(address _player)
        external
        view
        returns (uint256)
    {
        uint256 oldNetWorth = playerByAddress[_player].netWorth;
        uint256 newNetWorth = 0;
        for (
            uint8 i = 0;
            i < playerByAddress[_player].propertyOwned.length;
            i++
        ) {
            newNetWorth +=
                (properties[playerByAddress[_player].propertyOwned[i]].price) /
                2;
        }

        newNetWorth += playerByAddress[_player].balance;
        return newNetWorth;
    }

    function finePlayer(uint8 _playerId, uint256 amount) internal
    {
        require(
            playerByAddress[_playerId].balance >= amount,
            "You don't have enough money"
        );
        playerByAddress[_playerId].balance -= amount;
        emit playerPaidIncomeTax(_playerId);
    }

    function _addAdmin(address _newAdmin) internal {
        grantRole(DEFAULT_ADMIN_ROLE, _newAdmin);
    }

    function _addPlayer(address _playerAddress) internal {
        require(
            playerByAddress[_playerAddress] == false,
            "Player already exists"
        );
        uint256[] memory _properties;
        playerByAddress[_playerAddress] = Player(_playerIdCounter, 0, _properties, _startingBalance, 0, _playerAddress, true);
    }

    function _buildHouse(uint8 _propertyIndex) internal {
        require(
            properties[_propertyIndex].owner.balance >
                properties[_propertyIndex].houseCost,
            "Not enough funds"
        );
        properties[_propertyIndex].owner.balance =
            properties[_propertyIndex].owner.balance -
            properties[_propertyIndex].houseCost;
        properties[_propertyIndex].houseCounter++;
    }

    function calcuateRent(uint8 _propertyIndex)
        internal
        view
        returns (uint256)
    {
        // base rent + house rent * house counter
        return
            properties[_propertyIndex].baseRent +
            (properties[_propertyIndex].houseRent *
                properties[_propertyIndex].houseCounter);
    }

    function destroyHouse(uint8 _propertyIndex, uint256 numberOfHouses) external activePlayer(properties[_propertyIndex].owner.playerAddress) {
        require(
            properties[_propertyIndex].houseCounter >= numberOfHouses,
            "Not enough houses"
        );
        properties[_propertyIndex].houseCounter -= numberOfHouses;
        // return the owner 50% of the house cost ~ this is reduced house tax
        properties[_propertyIndex].owner.balance +=
            (properties[_propertyIndex].houseCost * numberOfHouses) /
            2;
    }

    function _isActive(address user) internal view returns (bool) {
        require(Player[user]._isActive == false, "User is not active");
        return true;
    }

    modifier activePlayer(address _playerAddress) {
        require(msg.sender == _playerAddress, "Not Player");
        require(_isActive(_playerAddress), "Inactive User");
        require(hasRole(ACTIVE_PLAYER, _playerAddress), "Not your turn!");
        _;
    }
}
