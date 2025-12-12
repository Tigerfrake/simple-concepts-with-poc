// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Governance is Ownable {
    IERC20 public govToken;  // The token used for voting power

    struct Proposal {
        uint256 id;
        address proposer;
        string description;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        bool executed;
        mapping(address => bool) hasVoted;  // Track who voted to prevent double-voting
    }

    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    uint256 public votingPeriod = 300;  // ~1 day in blocks (assuming 15s/block)
    uint256 public quorum = 1000 * 10**18;  // Minimum tokens needed for a valid vote (adjust based on total supply)

    event ProposalCreated(uint256 id, address proposer, string description);
    event Voted(uint256 id, address voter, bool support, uint256 weight);
    event ProposalExecuted(uint256 id);

    constructor(IERC20 _govToken, address owner) Ownable(owner) {
        govToken = _govToken;
    }

    // Create a new proposal
    function propose(string memory _description) external {
        require(govToken.balanceOf(msg.sender) > 0, "Must hold tokens to propose");
        proposalCount++;
        Proposal storage p = proposals[proposalCount];
        p.id = proposalCount;
        p.proposer = msg.sender;
        p.description = _description;
        p.startBlock = block.number;
        p.endBlock = block.number + votingPeriod;
        p.executed = false;

        emit ProposalCreated(proposalCount, msg.sender, _description);
    }

    // Vote on a proposal
    function vote(uint256 _proposalId, bool _support) external {
        Proposal storage p = proposals[_proposalId];
        require(block.number >= p.startBlock && block.number <= p.endBlock, "Voting not active");
        require(!p.hasVoted[msg.sender], "Already voted");
        uint256 weight = govToken.balanceOf(msg.sender);
        require(weight > 0, "No voting power");

        p.hasVoted[msg.sender] = true;
        if (_support) {
            p.forVotes += weight;
        } else {
            p.againstVotes += weight;
        }

        emit Voted(_proposalId, msg.sender, _support, weight);
    }

    // Execute a passed proposal (for now, just marks as executed; add real logic later)
    function execute(uint256 _proposalId) external onlyOwner {
        Proposal storage p = proposals[_proposalId];
        require(block.number > p.endBlock, "Voting not ended");
        require(!p.executed, "Already executed");
        require(p.forVotes > p.againstVotes, "Did not pass");
        require(p.forVotes + p.againstVotes >= quorum, "Quorum not met");

        p.executed = true;
        // Add execution logic here, e.g., transfer funds or call another contract

        emit ProposalExecuted(_proposalId);
    }
}