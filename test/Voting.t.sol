// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";
import {VotingContract} from "../../src/Voting/Voting.sol";

/**
 * @title VotingContract Test Suite
 * @dev Tests for all functionalities of the VotingContract
 */
contract VotingTest is Test {
    // --- STATE VARIABLES ---

    VotingContract public votingContract;

    // --- CONSTANTS FOR READABILITY ---

    // Using constants makes tests much clearer than using raw addresses
    address public constant CHAIRPERSON = address(0x1);
    address public constant VOTER_A = address(0x2);
    address public constant VOTER_B = address(0x3);
    address public constant UNREGISTERED_USER = address(0x4);

    string[] public proposalNames;

    // --- SETUP ---

    /**
     * @dev This function is run before each test case to set up a clean state.
     *      It deploys a new instance of the VotingContract.
     */
    function setUp() public {
        // Create an array of proposal names for the constructor
        proposalNames = new string[](3);
        proposalNames[0] = "Proposal A";
        proposalNames[1] = "Proposal B";
        proposalNames[2] = "Proposal C";

        // Prank as the CHAIRPERSON to ensure they are set as the owner on deployment
        vm.startPrank(CHAIRPERSON);
        votingContract = new VotingContract(proposalNames);
        vm.stopPrank();
    }

    // --- TEST: CONSTRUCTOR & INITIAL STATE ---

    function test_InitialState() public {
        assertEq(
            votingContract.chairperson(),
            CHAIRPERSON,
            "Chairperson should be the deployer"
        );
        assertEq(
            votingContract.getProposalCount(),
            3,
            "Should have 3 proposals initially"
        );

        // Check if chairperson has the right to vote
        (, , uint256 weight) = votingContract.voters(CHAIRPERSON);
        assertEq(weight, 1, "Chairperson should have a voting weight of 1");

        // Check proposal details
        (string memory name, uint256 voteCount) = votingContract.proposals(0);
        assertEq(name, "Proposal A", "Proposal 0 name is incorrect");
        assertEq(voteCount, 0, "Proposal 0 vote count should be 0");
    }

    // --- TEST: giveRightToVote ---

    function test_GiveRightToVote_Success() public {
        // ARRANGE: Prank as chairperson to call the function
        vm.startPrank(CHAIRPERSON);

        // EXPECT: An event to be emitted
        // vm.expectEmit(true, false, false, false);
        // emit votingContract.VoterRegistered(VOTER_A);

        // ACT: Call the function
        votingContract.giveRightToVote(VOTER_A);
        vm.stopPrank();

        // ASSERT: Check the voter's weight
        (, , uint256 weight) = votingContract.voters(VOTER_A);
        assertEq(weight, 1, "Voter A should now have a voting weight of 1");
    }

    function testRevert_GiveRightToVote_WhenNotChairperson() public {
        // Prank as a regular user to try and call the function
        vm.startPrank(VOTER_A);
        vm.expectRevert("Only chairperson can call this");
        votingContract.giveRightToVote(VOTER_B);
        vm.stopPrank();
    }

    function testRevert_GiveRightToVote_WhenAlreadyRegistered() public {
        // ARRANGE: Register a voter first
        vm.startPrank(CHAIRPERSON);
        votingContract.giveRightToVote(VOTER_A);

        // ACT & ASSERT: Try to register them again and expect a revert
        vm.expectRevert("Voter already registered");
        votingContract.giveRightToVote(VOTER_A);
        vm.stopPrank();
    }

    // --- TEST: vote ---

    function test_Vote_Success() public {
        // ARRANGE: Register Voter A
        vm.startPrank(CHAIRPERSON);
        votingContract.giveRightToVote(VOTER_A);
        vm.stopPrank();

        // ACT: Voter A casts a vote for proposal 1 ("Proposal B")
        vm.startPrank(VOTER_A);

        // EXPECT: An event should be emitted with VOTER_A and proposal index 1
        vm.expectEmit(true, true, false, true);
        emit VotingContract.VoteCast(VOTER_A, 1);
        votingContract.vote(1);
        vm.stopPrank();

        // ASSERT: Check the state changes
        assertTrue(
            votingContract.hasAddressVoted(VOTER_A),
            "Voter A should be marked as voted"
        );

        (, uint256 voteCount) = votingContract.proposals(1);
        assertEq(voteCount, 1, "Proposal 1 vote count should be 1");
    }

    function testRevert_Vote_WhenNotRegistered() public {
        vm.startPrank(UNREGISTERED_USER);
        vm.expectRevert("You don't have the right to vote");
        votingContract.vote(0);
        vm.stopPrank();
    }

    function testRevert_Vote_WhenAlreadyVoted() public {
        // ARRANGE: Register and have Voter A vote once
        vm.startPrank(CHAIRPERSON);
        votingContract.giveRightToVote(VOTER_A);
        vm.stopPrank();

        vm.startPrank(VOTER_A);
        votingContract.vote(0);

        // ACT & ASSERT: Try to vote again
        vm.expectRevert("You already voted");
        votingContract.vote(1);
        vm.stopPrank();
    }

    function testRevert_Vote_WithInvalidProposalIndex() public {
        vm.startPrank(CHAIRPERSON); // Chairperson can vote by default
        vm.expectRevert("Invalid proposal");
        votingContract.vote(99); // There are only 3 proposals (0, 1, 2)
        vm.stopPrank();
    }

    // --- TEST: winningProposal & winnerName ---

    function test_WinningProposal_And_WinnerName() public {
        // ARRANGE: Register voters
        vm.prank(CHAIRPERSON);
        votingContract.giveRightToVote(VOTER_A);

        vm.prank(CHAIRPERSON);
        votingContract.giveRightToVote(VOTER_B);

        // ACT: Have them vote
        // Proposal 2 ("Proposal C") gets 2 votes
        vm.prank(CHAIRPERSON);
        votingContract.vote(2);

        vm.prank(VOTER_A);
        votingContract.vote(2);

        // Proposal 1 ("Proposal B") gets 1 vote
        vm.prank(VOTER_B);
        votingContract.vote(1);

        // ASSERT
        assertEq(
            votingContract.winningProposal(),
            2,
            "Winning proposal index should be 2"
        );
        assertEq(
            votingContract.winnerName(),
            "Proposal C",
            "Winner name should be 'Proposal C'"
        );
    }

    function test_WinningProposal_InCaseOfTie() public {
        // In case of a tie, the function should return the proposal with the lower index.

        // ARRANGE & ACT:
        // Vote for Proposal 1
        vm.prank(CHAIRPERSON);
        votingContract.vote(1);

        // Vote for Proposal 2
        vm.prank(CHAIRPERSON);
        votingContract.giveRightToVote(VOTER_A);

        vm.prank(VOTER_A);
        votingContract.vote(2);

        // Now Proposal 1 and 2 each have 1 vote
        // ARRANGE
        assertEq(
            votingContract.winningProposal(),
            1,
            "In a tie, the first proposal found with max votes should win"
        );
    }

    // --- TEST: View Functions ---

    function test_GetAllProposals() public {
        // ARRANGE: Cast a vote to change state
        vm.prank(CHAIRPERSON);
        votingContract.vote(0);

        // ACT
        (string[] memory names, uint256[] memory counts) = votingContract
            .getAllProposals();

        // ASSERT
        assertEq(names.length, 3, "Should return 3 proposal names");
        assertEq(counts.length, 3, "Should return 3 vote counts");

        assertEq(names[0], "Proposal A", "Name of first proposal is incorrect");
        assertEq(counts[0], 1, "Vote count of first proposal should be 1");
        assertEq(counts[1], 0, "Vote count of second proposal should be 0");
    }
}
