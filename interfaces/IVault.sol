// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IVault {

    struct Vault
    {
        address owner;
        uint8 totalSupply;
        uint8 balance;
        uint8[] playerIds; 
        uint8[] playerBalances;
    }

    function depositFund(address _registeree, uint256 _value) external;
    function withdrawFund(address _registeree, uint256 _value) external;
    function getVaultBalance(address _vault) external view returns (uint256);
    function getVaultBalanceOf(address _vault, address _owner) external view returns (uint256);

}
