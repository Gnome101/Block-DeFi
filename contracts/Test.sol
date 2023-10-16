// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Test {
    uint256 public num;

    constructor(uint256 _num) {
        num = _num;
    }

    function storeValue(uint256 _num) public {
        num = _num;
    }
}
