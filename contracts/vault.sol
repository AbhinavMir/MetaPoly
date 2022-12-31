// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

import "../interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @dev `Vault` a contract that holds funds for Prize Pools
contract Vault is AccessControl {
    using SafeERC20 for IERC20;
    address public  prizePool;
    IERC20 public immutable  token;
    bytes32 public constant OWNER_ROLE = keccak256("OWNER_ROLE");
    bytes32 public constant PLAYER_ROLE = keccak256("PLAYER_ROLE");

    event Deposited(address indexed from, uint256 amount);
    event Withdrawal(address indexed to, uint256 amount);
    event PrizePoolSet(address indexed prizePool);
    event TokenSet(address indexed token);
    event OwnerAdded(address indexed owner);
    event OwnerRemoved(address indexed owner);

    constructor(IERC20 _token) {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        token = _token;
    }

    function depositTo(address to, uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        token.safeTransferFrom(msg.sender, to, amount);
        emit Deposited(to, amount);
    }
}
