// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";

// mock class using ERC20
contract ERC20Mock is ERC20Burnable {
    constructor (
        string memory name,
        string memory symbol,
        uint256 initialBalance
    ) payable ERC20(name, symbol) {
        _mint(msg.sender, initialBalance);
    }

    function mint(address to, uint256 value) public returns (bool) {
        _mint(to, value);
        return true;
    }

    function burn(address account, uint256 value) public returns (bool) {
        _burn(account, value);
        return true;
    } 
}
