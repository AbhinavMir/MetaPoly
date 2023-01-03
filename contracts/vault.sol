// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @dev `Vault` a contract that holds funds for Prize Pools
contract Vault is AccessControl {
    using SafeERC20 for IERC20;
    address public prizePool;
    IERC20 public immutable token;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant PLAYER_ROLE = keccak256("PLAYER_ROLE");
    uint256 public registrationFee;
    event Deposited(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event PrizePoolSet(address indexed prizePool);
    event TokenSet(address indexed token);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    constructor(
        IERC20 _token,
        uint256 _registrationFee
    ) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
        registrationFee = _registrationFee;
    }

    function payRegistrationFee() external onlyRole(PLAYER_ROLE) {
        token.safeTransferFrom(msg.sender, address(this), registrationFee);
        emit Deposited(msg.sender, registrationFee);
    }

    function payOut(address _to, uint256 _amount) internal onlyRole(OWNER_ROLE) {
        token.safeTransfer(_to, _amount);
        emit Withdrawal(_to, _amount);
    }
}
