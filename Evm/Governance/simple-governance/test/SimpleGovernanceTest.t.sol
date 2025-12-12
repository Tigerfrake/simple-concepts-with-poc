// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";

import "../src/GovToken.sol";
import "../src/SimpleGovernance.sol";

contract GovernanceTest is Test {

    GovToken gov;
    Governance govSys;

    address alice = address(0xA11CE);
    address bob = address(0xB0B);
    address carol = address(0xC0C);
    address owner = makeAddr("owner");

    function setUp() public {
        gov = new GovToken(owner);       // deploy governance token
        govSys = new Governance(IERC20(address(gov)), owner);

        // distribute voting tokens
        vm.startPrank(owner);
        gov.transfer(alice, 2_000e18);
        gov.transfer(bob, 2_000e18);
        gov.transfer(carol, 5_00e18);
    }

    /*//////////////////////////////////////////////////////////////
                             PROPOSAL CREATION
    //////////////////////////////////////////////////////////////*/

    function testCreateProposal() public {
        vm.startPrank(alice);
        govSys.propose("Increase rewards");
        vm.stopPrank();

        (, address proposer,,,,,,) = govSys.proposals(1);

        assertEq(proposer, alice, "Proposer incorrect");
    }

    /*//////////////////////////////////////////////////////////////
                                VOTING
    //////////////////////////////////////////////////////////////*/

    function testVoteFor() public {
        // create proposal
        vm.startPrank(alice);
        govSys.propose("Test proposal");

        // bob votes FOR
        vm.startPrank(bob);
        govSys.vote(1, true);

        (,,,,, uint256 forVotes,,) = govSys.proposals(1);

        assertEq(forVotes, 2_000e18, "Votes not counted correctly");
    }

    function testVoteAgainst() public {
        vm.startPrank(alice);
        govSys.propose("Test proposal");

        vm.startPrank(bob);
        govSys.vote(1, false);

        (,,,,,, uint256 againstVotes,) = govSys.proposals(1);

        assertEq(againstVotes, 2_000e18);
    }

    function testRevertDoubleVoting() public {
        vm.startPrank(alice);
        govSys.propose("Test proposal");

        vm.startPrank(bob);
        govSys.vote(1, true);

        // attempt to vote agin
        vm.expectRevert("Already voted");
        govSys.vote(1, true);
    }

    /*//////////////////////////////////////////////////////////////
                              EXECUTION
    //////////////////////////////////////////////////////////////*/

    function testRevertExecuteBeforeEnd() public {
        vm.startPrank(alice);
        govSys.propose("Proposal");

        vm.startPrank(bob);
        govSys.vote(1, true);

        // trying to execute before endBlock → FAILS
        vm.startPrank(owner);
        vm.expectRevert("Voting not ended");
        govSys.execute(1);
    }

    function testRevertExecuteIfNotPassed() public {
        vm.startPrank(alice);
        govSys.propose("Proposal");

        vm.startPrank(bob);
        govSys.vote(1, false); // vote AGAINST

        // move blocks past endBlock
        vm.roll(block.number + govSys.votingPeriod() + 1);

        // should fail because againstVotes > forVotes
        vm.startPrank(owner);
        vm.expectRevert("Did not pass");
        govSys.execute(1);
    }

    function testRevertExecuteIfNoQuorum() public {
        vm.startPrank(alice);
        govSys.propose("Proposal");

        vm.startPrank(carol);
        govSys.vote(1, true);

        vm.roll(block.number + govSys.votingPeriod() + 1);

        vm.startPrank(owner);
        vm.expectRevert("Quorum not met");
        govSys.execute(1);
    }

    function testExecuteSuccess() public {
        vm.startPrank(alice);
        govSys.propose("Proposal");

        // bob + carol vote FOR → 4000 votes
        vm.startPrank(bob);
        govSys.vote(1, true);
        vm.startPrank(carol);
        govSys.vote(1, true);

        vm.roll(block.number + govSys.votingPeriod() + 1);

        vm.startPrank(owner);
        govSys.execute(1);

        (,,,,,,, bool executed) = govSys.proposals(1);
        assertTrue(executed, "Proposal should be marked executed");
    }

    function testRevertDoubleExecute() public {
        vm.startPrank(alice);
        govSys.propose("Proposal");

        // bob + carol vote FOR → 4000 votes
        vm.startPrank(bob);
        govSys.vote(1, true);
        vm.startPrank(carol);
        govSys.vote(1, true);

        vm.roll(block.number + govSys.votingPeriod() + 1);

        vm.startPrank(owner);
        govSys.execute(1);

        (,,,,,,, bool executed) = govSys.proposals(1);
        assertTrue(executed, "Proposal should be marked executed");

        // re-attempt
        vm.expectRevert("Already executed");
        govSys.execute(1);
    }
}
