// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/TransparentLogicV1.sol";
import "../src/TransparentLogicV2.sol";

import {TransparentUpgradeableProxy, ITransparentUpgradeableProxy} 
    from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";

contract TransparentProxyV5Test is Test {
    TransparentLogicV1 implV1;
    TransparentLogicV2 implV2;

    TransparentUpgradeableProxy proxy;

    // This is the OWNER of ProxyAdmin (the upgrade key)
    address proxyAdminOwner = address(0xABCD);

    // Normal user
    address alice = address(0xA11CE);

    // ABI views of the proxy
    TransparentLogicV1 proxyAsV1;
    TransparentLogicV2 proxyAsV2;

    function setUp() public {
        // 1. Deploy implementation V1
        implV1 = new TransparentLogicV1();

        // 2. Encode initializer
        bytes memory data = abi.encodeWithSelector(
            TransparentLogicV1.initialize.selector, 123
        );

        // 3. Deploy Transparent Proxy
        // NOTE: This internally deploys ProxyAdmin(initialOwner)
        proxy = new TransparentUpgradeableProxy(
            address(implV1),
            proxyAdminOwner, // <- owner of the internal ProxyAdmin
            data
        );

        // 4. Attach V1 ABI to proxy address
        proxyAsV1 = TransparentLogicV1(address(proxy));
    }

    function test_user_can_call_logic() public {
        vm.prank(alice);
        proxyAsV1.setNumber(777);

        vm.prank(alice);
        assertEq(proxyAsV1.getNumber(), 777);
    }

    function test_admin_cannot_call_logic() public {
        // Get the actual ProxyAdmin address from the proxy
        address proxyAdminAddress =
            address(uint160(uint256(vm.load(
                address(proxy),
                bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
            ))));

        // Admin tries to call logic -> must revert with ProxyDeniedAdminAccess
        vm.prank(proxyAdminAddress);
        vm.expectRevert(
            TransparentUpgradeableProxy.ProxyDeniedAdminAccess.selector
        );
        proxyAsV1.getNumber();
    }

    function test_upgrade_via_proxyAdmin_and_preserve_storage() public {
        // 1. Mutate storage as user
        vm.prank(alice);
        proxyAsV1.setNumber(888);
        assertEq(proxyAsV1.getNumber(), 888);

        // 2. Deploy V2
        implV2 = new TransparentLogicV2();

        // 3. Get ProxyAdmin address from EIP-1967 slot
        address proxyAdminAddress =
            address(uint160(uint256(vm.load(
                address(proxy),
                bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
            ))));

        ProxyAdmin admin = ProxyAdmin(proxyAdminAddress);

        // 4. Upgrade via ProxyAdmin OWNER
        vm.prank(proxyAdminOwner);
        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)),
            address(implV2),
            ""
        );

        // 5. Rebind ABI to V2
        proxyAsV2 = TransparentLogicV2(address(proxy));

        // 6. STORAGE STILL INTACT
        assertEq(proxyAsV2.getNumber(), 888);

        // 7. NEW LOGIC WORKS
        vm.prank(alice);
        proxyAsV2.increment();
        assertEq(proxyAsV2.getNumber(), 889);

        // 8. CONFIRM NEW CODE
        assertEq(proxyAsV2.version(), "V2");
    }

    function test_non_owner_cannot_upgrade() public {
        implV2 = new TransparentLogicV2();

        address proxyAdminAddress =
            address(uint160(uint256(vm.load(
                address(proxy),
                bytes32(uint256(keccak256("eip1967.proxy.admin")) - 1)
            ))));

        ProxyAdmin admin = ProxyAdmin(proxyAdminAddress);

        // alice is NOT the ProxyAdmin owner
        vm.prank(alice);
        vm.expectRevert();
        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(proxy)),
            address(implV2),
            ""
        );
    }
}
