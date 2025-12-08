// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TransparentLogicV1 is Initializable {
    // Storage slot 0
    uint256 public number;

    // initializer instead of constructor
    function initialize(uint256 _num) public initializer {
        number = _num;
    }

    function setNumber(uint256 _num) external {
        number = _num;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }
}
