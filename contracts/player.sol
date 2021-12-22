//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "./property.sol";

contract PlayerContract{

    struct Player
    {
        string name;
        uint256 balance;
        string[] propertiesByID;
    }

}