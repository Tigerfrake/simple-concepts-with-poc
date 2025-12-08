// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/SimpleLogicV1.sol";
import "../src/SimpleLogicV2.sol";

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract UUPSTest is Test {
    // proxy instance 
    SimpleLogicV1 public v1;
    SimpleLogicV2 public v2;
    ERC1967Proxy public proxy;

    // implementations
    SimpleLogicV1 public v1Impl;
    SimpleLogicV2 public v2Impl;

    address owner = address(0xCAFE);

    function setUp() public {
        // Deploy V1
        v1Impl = new SimpleLogicV1();

        // Encode initializer
        bytes memory data = abi.encodeWithSelector(
            SimpleLogicV1.initialize.selector, 123, owner
        );

        // Deploy proxy pointing to V1
        proxy = new ERC1967Proxy(address(v1Impl), data);

        // Attach V1 interface to proxy
        v1 = SimpleLogicV1(address(proxy));

        // Deploy V2
        v2Impl = new SimpleLogicV2();
    }

    function test_V1_Works() public {
        assertEq(v1.getNumber(), 123);

        v1.setNumber(555);
        assertEq(v1.getNumber(), 555);
    }

    function test_owner_transfer_v1() public {
        // check initial owner
        assertEq(v1.owner(), owner);

        // transfer ownership
        vm.prank(owner);
        v1.transferOwnership(address(0xBEEF));
        assertEq(v1.owner(), address(0xBEEF));
    }

    function test_Upgrade_To_V2() public {
        // first check V1 works
        v1.setNumber(555);
        assertEq(v1.getNumber(), 555);

        // Upgrade through proxy
        vm.prank(owner);
        v1.upgradeTo(address(v2Impl), "");

        // Attach V2 interface
        v2 = SimpleLogicV2(address(proxy));

        // STORAGE STILL INTACT
        assertEq(v2.getNumber(), 555);

        // NEW FUNCTION WORKS
        v2.increment();
        assertEq(v2.getNumber(), 556);
        
        // NEW LOGIC VERSION
        assertEq(v2.version(), "V2");
    }

    function test_Unauthorized_Upgrade_Reverts() public {
        vm.prank(address(0xBEEF));
        vm.expectRevert();
        v1.upgradeTo(address(v2), ""); // should revert because not owner
    }

    function test_owner_transfer_v2() public {
        // Upgrade through proxy
        vm.prank(owner);
        v1.upgradeTo(address(v2Impl), "");

        // Attach V2 interface
        v2 = SimpleLogicV2(address(proxy));

        // check initial owner
        assertEq(v2.owner(), owner);

        // transfer ownership
        vm.prank(owner);
        v2.transferOwnership(address(0xBEEF));
        assertEq(v2.owner(), address(0xBEEF));
    }
}
