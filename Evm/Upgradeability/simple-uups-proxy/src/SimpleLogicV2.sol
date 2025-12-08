// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./SimpleLogicV1.sol";

contract SimpleLogicV2 is SimpleLogicV1 {

    function increment() external {
        number += 1;
    }

    function version() external pure returns (string memory) {
        return "V2";
    }
}
