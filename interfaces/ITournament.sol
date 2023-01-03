// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface ITournament {

    struct Match 
    {
        address[] participants;
        address[] winners;
    }

    struct Player
    {
        uint8 _index;
        uint8 position;
        uint8[] propertyOwned;
        uint256 balance;   
        uint256 netWorth;
        address playerAddress;
        bool _isActive;
    }

    struct Property
    {
        bytes32 name;
        uint8 price;
        uint8 position;
        uint8 baseRent;
        uint8 houseCounter;
        uint8 houseCost;
        uint8 houseRent;
        Player owner;
        // address owner;
        PropertyState state;
    }

    enum PropertyState 
    {
        Unowned,
        Owned,
        Mortgaged,
        ForSale,
        SwapRequested
    }

    // function rollDice() external; - Creating random numbers every roll is very expensive using Chainlink.

    function nextTurn() external;

    function movePlayer(uint8 _playerIndex, uint8 _playerPosition) external;

    function passTurn(address _player) external;

    function distributeCapital(uint8 _players) external;

    function payBank(uint256 _amount) external;

    function receiveCapital(uint256 _amount) external;

    function goToJail(address _player) external;

    function freeFromJail(address _player) external;

    function payForJail(address _player) external;

    function buyProperty(uint8 _propertyIndex) external;

    function sellProperty(uint8 _propertyIndex) external;

    function mortgageProperty(uint8 _propertyIndex) external;

    function unmortgageProperty(uint8 _propertyIndex) external;

    function buyHouse(uint8 _propertyIndex, uint8 _numberOfHouses) external;

    function sellHouse(uint8 _propertyIndex, uint8 _numberOfHouses) external;

    function passGo() external;

    function forfeit(uint8 _playerId) external;

    // function getPlayer(address _player) public view returns (Player);

    // function getProperty(uint8 _propertyIndex) public view returns (Property);

    event matchStarted(uint8 _players);
    event matchEnded(uint8 _players);
    event playerTurn(address _player);
    event playerAdded(uint8 _playerIndex, address _playerAddress);
    event playerMoved(uint8 _byDice, uint8 _playerId, uint8 _playerPosition);
    event playerPassed(address _player);
    event propertyBought(address _player, uint8 _propertyIndex);
    event propertySold(address _player, uint8 _propertyIndex);
    event propertyMortgaged(address _player, uint8 _propertyIndex);
    event propertyUnmortgaged(address _player, uint8 _propertyIndex);
    event propertyHouseBought(address _player, uint8 _propertyIndex, uint8 _numberOfHouses);
    event propertyHouseSold(address _player, uint8 _propertyIndex, uint8 _numberOfHouses);
    event passedGo(address _player);
    event playerJailed(uint8 _playerId);
    event playerUnjailed(address _player);
    event playerWon(address _player);
    event playerLost(address _player);
    event turnEnded(uint8 _playerId, uint8 _nextPlayerId);
    event playerForfeited(uint8 _playerId);
    event playerPaidRent(address _player, uint8 _propertyIndex, uint256 _amount);
    event DiceThrown(uint256 result, uint256 blockNumber, string warning);
}
