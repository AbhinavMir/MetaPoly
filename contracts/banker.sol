//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

contract Banker {
    address public banker;
    address[] public players;

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
