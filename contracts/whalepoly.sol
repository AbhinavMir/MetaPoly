pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20Detailed.sol";

contract WPLYtoken is ERC20, ERC20Detailed {
    constructor(uint256 initialSupply) ERC20Detailed("WhalePoly", "WPLY", 18) public {
        _mint(msg.sender, initialSupply);
    }
}