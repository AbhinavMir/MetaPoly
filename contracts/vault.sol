// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../interfaces/IVault.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";

/// @dev `Vault` a contract that holds funds for Prize Pools
contract Vault is IVault, AccessControl {
    using SafeERC20 for IERC20;

    address public immutable token;
    address public immutable tournamentAddress;

    constructor(address _token, address _tournamentAddress) {
        token = _token;
        tournamentAddress = _tournamentAddress;
        _setupRole(DEFAULT_ADMIN_ROLE, _tournamentAddress);
    }

    function deposit(uint256 _amount, address _player) external
    {

    }

    function transfer(address userWallet, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        require(balance() >= amount, "Vault: Not enough amount on the Vault");
        IERC20(token).safeTransfer(userWallet, amount);
    }

    function getFeeFromPlayer(address _from, uint256 amount)
        external
        onlyRole(DEFAULT_ADMIN_ROLE)
    {
        IERC20(token).safeTransferFrom(_from, address(this), amount);
    }

    function balance() public view returns (uint256) {
        return IERC20(token).balanceOf(address(this));
    }
}