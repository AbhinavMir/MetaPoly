//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Property {
    address public banker;
    address[] public players;

    struct _property
    {
        address owner;
        bytes23 name;
        uint8 baseRent;
        uint8 houses;
        uint8 rentMultiplier;
        uint8 mortgage;
    }

    constructor(address _banker, address[] memory _players) {
        _banker = banker;
        _players = players;
    }

    function addPlayers(address _player) public
    {
        require(players.length < 4);
        players.push(_player);
    }

    function removePlayer(uint _index) public
    {
        delete players[_index];
    }

    function distributeCapital() public 
    {

    }
}
