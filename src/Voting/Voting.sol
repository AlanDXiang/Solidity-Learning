// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title VotingContract
 * @dev A simple voting system where voters can vote for proposals
 */
contract VotingContract {
    // --- STRUCTS ---

    // Represents a voter with their voting status
    struct Voter {
        bool hasVoted; // Has this person voted?
        uint256 votedFor; // Which proposal did they vote for?
        uint256 weight; // Voting power (1 = can vote, 0 = cannot)
    }

    // Represents a proposal/option to vote for
    struct Proposal {
        string name; // Name of the proposal (e.g., "Option A")
        uint256 voteCount; // Total votes received
    }

    // --- STATE VARIABLES ---

    address public chairperson; // Person who created the contract
    mapping(address => Voter) public voters; // Tracks all voters
    Proposal[] public proposals; // Array of all proposals

    // --- EVENTS ---

    // Emitted when someone votes
    event VoteCast(address indexed voter, uint256 indexed proposalIndex);

    // Emitted when a new voter is registered
    event VoterRegistered(address indexed voter);

    // Emitted when a new proposal is added
    event ProposalAdded(string name, uint256 index);

    // --- MODIFIERS ---

    // Only the chairperson can call functions with this modifier
    modifier onlyChairperson() {
        require(msg.sender == chairperson, "Only chairperson can call this");
        _;
    }

    // --- CONSTRUCTOR ---

    /**
     * @dev Initialize the contract with proposal names
     * @param proposalNames Array of proposal names (e.g., ["Option A", "Option B"])
     */
    constructor(string[] memory proposalNames) {
        chairperson = msg.sender; // Person deploying = chairperson
        voters[chairperson].weight = 1; // Chairperson can vote

        // Create all proposals
        for (uint256 i = 0; i < proposalNames.length; i++) {
            proposals.push(Proposal({name: proposalNames[i], voteCount: 0}));

            emit ProposalAdded(proposalNames[i], i);
        }
    }

    // --- FUNCTIONS ---

    /**
     * @dev Give a voter the right to vote
     * @param voter Address of the voter to register
     */
    function giveRightToVote(address voter) external onlyChairperson {
        require(!voters[voter].hasVoted, "Voter already voted");
        require(voters[voter].weight == 0, "Voter already registered");

        voters[voter].weight = 1;
        emit VoterRegistered(voter);
    }

    /**
     * @dev Cast a vote for a proposal
     * @param proposalIndex Index of the proposal to vote for
     */
    function vote(uint256 proposalIndex) external {
        Voter storage sender = voters[msg.sender];

        require(sender.weight > 0, "You don't have the right to vote");
        require(!sender.hasVoted, "You already voted");
        require(proposalIndex < proposals.length, "Invalid proposal");

        sender.hasVoted = true;
        sender.votedFor = proposalIndex;

        proposals[proposalIndex].voteCount += sender.weight;

        emit VoteCast(msg.sender, proposalIndex);
    }

    /**
     * @dev Get the index of the winning proposal
     * @return winningProposal_ Index of the proposal with most votes
     */
    function winningProposal() public view returns (uint256 winningProposal_) {
        uint256 winningVoteCount = 0;

        for (uint256 i = 0; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposal_ = i;
            }
        }
    }

    /**
     * @dev Get the name of the winning proposal
     * @return winnerName_ Name of the winning proposal
     */
    function winnerName() external view returns (string memory winnerName_) {
        winnerName_ = proposals[winningProposal()].name;
    }

    /**
     * @dev Get all proposals with their vote counts
     * @return Array of proposal names and their vote counts
     */
    function getAllProposals()
        external
        view
        returns (string[] memory names, uint256[] memory voteCounts)
    {
        uint256 length = proposals.length;
        names = new string[](length);
        voteCounts = new uint256[](length);

        for (uint256 i = 0; i < length; i++) {
            names[i] = proposals[i].name;
            voteCounts[i] = proposals[i].voteCount;
        }
    }

    /**
     * @dev Get total number of proposals
     */
    function getProposalCount() external view returns (uint256) {
        return proposals.length;
    }

    /**
     * @dev Check if an address has voted
     */
    function hasAddressVoted(address voter) external view returns (bool) {
        return voters[voter].hasVoted;
    }
}
