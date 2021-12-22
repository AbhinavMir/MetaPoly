//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

contract Property {
    address public banker;
    address[] public players;

    struct ownedProperty
    {
        address owner;
        bytes23 name;
        uint8 id;
        uint8 baseRent;
        uint8 houseCounter;
        uint8 rentMultiplier;
        uint8 mortgage;
        bool utility;
        bool railroad;
        bool mortgaged;
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
        /// @dev Initiate game with function
    }
}
