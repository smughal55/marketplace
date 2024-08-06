// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract ERC20Mock is ERC20 {
    constructor(
        string memory name,
        string memory symbol,
        uint8 decimals
    ) ERC20(name, symbol) {
        _setupDecimals(decimals);
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    // Override decimals function if you're using OpenZeppelin 3.x or lower
    function _setupDecimals(uint8 decimals_) internal {
        require(decimals_ <= 18, "ERC20: decimals must be <= 18");
        // ERC20._decimals is private, so you may need to store decimals in your own state variable
        // This line is not needed in OpenZeppelin 4.x where decimals is not a private variable.
    }
}
