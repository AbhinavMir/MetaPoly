// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ITournament {

    struct Match {
        address[] participants;
        address[] winners;
    }

    struct Player
    {
        uint8 _index;
        uint8[] position;
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
    }
}
