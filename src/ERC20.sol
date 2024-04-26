// SPDX-License-Identifier: MIT
// OpenZeppelin Contracts (last updated v5.0.0) (token/ERC20/ERC20.sol)

pragma solidity ^0.8.20;

import { ERC20 } from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

contract myToken is ERC20{

    event mintTo(address _to, uint256 _amount);

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_){

    }
    function mint(address _to, uint256 _amount) public {
        require(_amount > 0, "amount <= 0");

        _mint(_to, _amount);

        emit mintTo(_to, _amount);
    }
}