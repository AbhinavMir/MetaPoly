//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./property.sol";

contract Government {
    address public banker;
    address[] public players;

    constructor(address _banker, address[] memory _players) {
        _banker = banker;
        _players = players;
    }

    function addPlayers(address _player) public
    {
        require(players.length < 7, "Maximum players should be 6");
        players.push(_player);
    }

    /// @dev Use this fuction to either ban players or kick them post-bankruptcy
    function removePlayer(uint _index) public
    {
        delete players[_index];
    }

    function distributeCapital() public 
    {

    }

    function sendToJail(address _player) public
    {

    }

    function getBalance(address _player) view public
    {

    }
}
