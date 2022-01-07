//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

contract Banker{
    function sendToJail(address _JailedPlayer) external onlyRole(BANKER)
    {
        revokeRole(
            "PLAYER", _JailedPlayer
        );

        grantRole(
            "JAILED_USER", _JailedPlayer
        );
    }
}