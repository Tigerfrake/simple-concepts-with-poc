// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./TransparentLogicV1.sol";

contract TransparentLogicV2 is TransparentLogicV1 {
    // new function appended (storage layout unchanged)
    function increment() external {
        number += 1;
    }

    function version() external pure returns (string memory) {
        return "V2";
    }
}
