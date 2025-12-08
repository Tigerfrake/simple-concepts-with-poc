// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SimpleLogicV1 is Initializable, UUPSUpgradeable, OwnableUpgradeable {
    uint256 public number;

    /// replaces constructor
    function initialize(uint256 _num, address owner) public initializer {
        __Ownable_init(owner);
        number = _num;
    }

    function setNumber(uint256 _num) external {
        number = _num;
    }

    function getNumber() external view returns (uint256) {
        return number;
    }

    // EXPOSE upgradeTo publicly
    function upgradeTo(address newImplementation, bytes memory data) public onlyOwner {
        upgradeToAndCall(newImplementation, data); // only callable by proxy
    }

    /// upgrade authorization
    // Only the owner can authorize an upgrade
    function _authorizeUpgrade(address) internal override onlyOwner {}
}
