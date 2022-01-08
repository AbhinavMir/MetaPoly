// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

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
        address player;
    }

    struct Property
    {
        bytes32 name;
        uint8 position;
        uint8 baseRent;
        uint8 houseCounter;
        uint8 houseCost;
        bool mortgaged;
        bool owned;
        Player owner;
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

    function forfeit(address _player) external;

    // function getPlayer(address _player) public view returns (Player);

    // function getProperty(uint8 _propertyIndex) public view returns (Property);

    event MatchStarted(uint8 _players);
    event MatchEnded(uint8 _players);
    event PlayerTurn(address _player);
    event PlayerPassed(address _player);
    event PropertyBought(address _player, uint8 _propertyIndex);
    event PropertySold(address _player, uint8 _propertyIndex);
    event PropertyMortgaged(address _player, uint8 _propertyIndex);
    event PropertyUnmortgaged(address _player, uint8 _propertyIndex);
    event PropertyHouseBought(address _player, uint8 _propertyIndex, uint8 _numberOfHouses);
    event PropertyHouseSold(address _player, uint8 _propertyIndex, uint8 _numberOfHouses);
    event PassedGo(address _player);
    event PlayerJailed(address _player);
    event PlayerUnjailed(address _player);
    event PlayerWon(address _player);
    event PlayerLost(address _player);
}
