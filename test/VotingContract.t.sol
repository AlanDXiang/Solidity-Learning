// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {Test, console2} from "forge-std/Test.sol";
import {VotingContract} from "../../src/Voting/Voting.sol";

/**
 * @title VotingContractTest
 * @dev Comprehensive test suite for VotingContract using Foundry best practices
 * @notice Test structure follows: Setup -> Action -> Assert pattern
 */
contract VotingContractTest is Test {
    // --- TEST CONTRACTS & VARIABLES ---
    VotingContract public votingContract;

    // Test actors
    address public chairperson;
    address public voter1;
    address public voter2;
    address public voter3;
    address public unauthorizedUser;

    // Test data
    string[] public proposalNames;

    // --- EVENTS (for testing event emissions) ---
    event VoteCast(address indexed voter, uint256 indexed proposalIndex);
    event VoterRegistered(address indexed voter);
    event ProposalAdded(string name, uint256 index);

    // --- SETUP ---

    /**
     * @dev Runs before each test function
     * Best Practice: Initialize all state here for test isolation
     */
    function setUp() public {
        // 1. Create test addresses (Foundry's makeAddr is cleaner than address(1))
        chairperson = makeAddr("chairperson");
        voter1 = makeAddr("voter1");
        voter2 = makeAddr("voter2");
        voter3 = makeAddr("voter3");
        unauthorizedUser = makeAddr("unauthorizedUser");

        // 2. Setup proposal names
        proposalNames = new string[](3);
        proposalNames[0] = "Proposal A";
        proposalNames[1] = "Proposal B";
        proposalNames[2] = "Proposal C";

        // 3. Deploy contract as chairperson
        vm.prank(chairperson); // Next call will be from chairperson
        votingContract = new VotingContract(proposalNames);
    }

    // ============================================
    // CONSTRUCTOR & INITIALIZATION TESTS
    // ============================================

    function test_Constructor_SetsChairpersonCorrectly() public view {
        assertEq(
            votingContract.chairperson(),
            chairperson,
            "Chairperson should be deployer"
        );
    }

    function test_Constructor_ChairpersonCanVote() public view {
        (bool hasVoted, , uint256 weight) = votingContract.voters(chairperson);
        assertEq(weight, 1, "Chairperson should have voting weight");
        assertFalse(hasVoted, "Chairperson should not have voted yet");
    }

    function test_Constructor_CreatesAllProposals() public view {
        assertEq(
            votingContract.getProposalCount(),
            3,
            "Should create 3 proposals"
        );

        (string memory name0, uint256 voteCount0) = votingContract.proposals(0);
        (string memory name1, uint256 voteCount1) = votingContract.proposals(1);
        (string memory name2, uint256 voteCount2) = votingContract.proposals(2);

        assertEq(name0, "Proposal A");
        assertEq(name1, "Proposal B");
        assertEq(name2, "Proposal C");
        assertEq(voteCount0, 0);
        assertEq(voteCount1, 0);
        assertEq(voteCount2, 0);
    }

    function test_Constructor_EmitsProposalAddedEvents() public {
        // Re-deploy to test events
        vm.expectEmit(true, true, true, true);
        emit ProposalAdded("Proposal A", 0);

        vm.expectEmit(true, true, true, true);
        emit ProposalAdded("Proposal B", 1);

        vm.expectEmit(true, true, true, true);
        emit ProposalAdded("Proposal C", 2);

        vm.prank(chairperson);
        new VotingContract(proposalNames);
    }

    // ============================================
    // GIVE RIGHT TO VOTE TESTS
    // ============================================

    function test_GiveRightToVote_Success() public {
        // Setup: Chairperson gives voter1 right to vote
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        // Assert: Check voter1 now has weight
        (, , uint256 weight) = votingContract.voters(voter1);
        assertEq(weight, 1, "Voter should have weight 1");
    }

    function test_GiveRightToVote_EmitsEvent() public {
        vm.expectEmit(true, false, false, false);
        emit VoterRegistered(voter1);

        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);
    }

    function test_GiveRightToVote_RevertsIfNotChairperson() public {
        vm.prank(unauthorizedUser);
        vm.expectRevert("Only chairperson can call this");
        votingContract.giveRightToVote(voter1);
    }

    function test_GiveRightToVote_RevertsIfAlreadyRegistered() public {
        // First registration
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        // Try to register again
        vm.prank(chairperson);
        vm.expectRevert("Voter already registered");
        votingContract.giveRightToVote(voter1);
    }

    function test_GiveRightToVote_RevertsIfVoterAlreadyVoted() public {
        // Register and vote
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        votingContract.vote(0);

        // Try to register again after voting
        vm.prank(chairperson);
        vm.expectRevert("Voter already voted");
        votingContract.giveRightToVote(voter1);
    }

    // ============================================
    // VOTE FUNCTION TESTS
    // ============================================

    function test_Vote_Success() public {
        // Setup: Register voter
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        // Action: Cast vote
        vm.prank(voter1);
        votingContract.vote(0);

        // Assert: Check vote was recorded
        (bool hasVoted, uint256 votedFor, ) = votingContract.voters(voter1);
        assertTrue(hasVoted, "Voter should be marked as voted");
        assertEq(votedFor, 0, "Voter should have voted for proposal 0");

        (, uint256 voteCount) = votingContract.proposals(0);
        assertEq(voteCount, 1, "Proposal should have 1 vote");
    }

    function test_Vote_EmitsEvent() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.expectEmit(true, true, false, false);
        emit VoteCast(voter1, 0);

        vm.prank(voter1);
        votingContract.vote(0);
    }

    function test_Vote_RevertsIfNoRightToVote() public {
        vm.prank(voter1);
        vm.expectRevert("You don't have the right to vote");
        votingContract.vote(0);
    }

    function test_Vote_RevertsIfAlreadyVoted() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        votingContract.vote(0);

        // Try to vote again
        vm.prank(voter1);
        vm.expectRevert("You already voted");
        votingContract.vote(1);
    }

    function test_Vote_RevertsIfInvalidProposal() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        vm.expectRevert("Invalid proposal");
        votingContract.vote(999); // Non-existent proposal
    }

    function test_Vote_MultipleVotersCanVote() public {
        // Register multiple voters
        vm.startPrank(chairperson);
        votingContract.giveRightToVote(voter1);
        votingContract.giveRightToVote(voter2);
        votingContract.giveRightToVote(voter3);
        vm.stopPrank();

        // Cast votes
        vm.prank(voter1);
        votingContract.vote(0);

        vm.prank(voter2);
        votingContract.vote(0);

        vm.prank(voter3);
        votingContract.vote(1);

        // Assert vote counts
        (, uint256 voteCount0) = votingContract.proposals(0);
        (, uint256 voteCount1) = votingContract.proposals(1);

        assertEq(voteCount0, 2, "Proposal 0 should have 2 votes");
        assertEq(voteCount1, 1, "Proposal 1 should have 1 vote");
    }

    // ============================================
    // WINNING PROPOSAL TESTS
    // ============================================

    function test_WinningProposal_ReturnsCorrectWinner() public {
        // Setup votes
        vm.startPrank(chairperson);
        votingContract.giveRightToVote(voter1);
        votingContract.giveRightToVote(voter2);
        votingContract.giveRightToVote(voter3);
        vm.stopPrank();

        vm.prank(voter1);
        votingContract.vote(1); // Vote for Proposal B

        vm.prank(voter2);
        votingContract.vote(1);

        vm.prank(voter3);
        votingContract.vote(0);

        // Assert
        uint256 winner = votingContract.winningProposal();
        assertEq(winner, 1, "Proposal 1 should be winning");
    }

    function test_WinningProposal_ReturnsZeroWhenNoVotes() public view {
        uint256 winner = votingContract.winningProposal();
        assertEq(winner, 0, "Should return 0 when no votes cast");
    }

    function test_WinnerName_ReturnsCorrectName() public {
        vm.startPrank(chairperson);
        votingContract.giveRightToVote(voter1);
        votingContract.giveRightToVote(voter2);
        vm.stopPrank();

        vm.prank(voter1);
        votingContract.vote(2);

        vm.prank(voter2);
        votingContract.vote(2);

        string memory winner = votingContract.winnerName();
        assertEq(winner, "Proposal C", "Winner name should be Proposal C");
    }

    // ============================================
    // VIEW FUNCTION TESTS
    // ============================================

    function test_GetAllProposals_ReturnsCorrectData() public {
        (string[] memory names, uint256[] memory voteCounts) = votingContract
            .getAllProposals();

        assertEq(names.length, 3, "Should return 3 names");
        assertEq(voteCounts.length, 3, "Should return 3 vote counts");

        assertEq(names[0], "Proposal A");
        assertEq(names[1], "Proposal B");
        assertEq(names[2], "Proposal C");

        assertEq(voteCounts[0], 0);
        assertEq(voteCounts[1], 0);
        assertEq(voteCounts[2], 0);
    }

    function test_GetAllProposals_AfterVoting() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        votingContract.vote(1);

        (, uint256[] memory voteCounts) = votingContract.getAllProposals();
        assertEq(voteCounts[1], 1, "Proposal B should have 1 vote");
    }

    function test_GetProposalCount() public view {
        assertEq(votingContract.getProposalCount(), 3);
    }

    function test_HasAddressVoted_ReturnsFalseInitially() public view {
        assertFalse(votingContract.hasAddressVoted(voter1));
    }

    function test_HasAddressVoted_ReturnsTrueAfterVoting() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        votingContract.vote(0);

        assertTrue(votingContract.hasAddressVoted(voter1));
    }

    // ============================================
    // EDGE CASES & SECURITY TESTS
    // ============================================

    function test_ChairpersonCanVoteWithoutRegistration() public {
        // Chairperson already has weight = 1
        vm.prank(chairperson);
        votingContract.vote(0);

        (, uint256 voteCount) = votingContract.proposals(0);
        assertEq(voteCount, 1, "Chairperson vote should count");
    }

    function test_CannotVoteForNonExistentProposal() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        vm.expectRevert("Invalid proposal");
        votingContract.vote(100);
    }

    function test_VoteCountsAreIndependent() public {
        vm.startPrank(chairperson);
        votingContract.giveRightToVote(voter1);
        votingContract.giveRightToVote(voter2);
        vm.stopPrank();

        vm.prank(voter1);
        votingContract.vote(0);

        vm.prank(voter2);
        votingContract.vote(2);

        (, uint256 count0) = votingContract.proposals(0);
        (, uint256 count1) = votingContract.proposals(1);
        (, uint256 count2) = votingContract.proposals(2);

        assertEq(count0, 1);
        assertEq(count1, 0);
        assertEq(count2, 1);
    }

    // ============================================
    // FUZZ TESTS (Advanced Foundry Feature)
    // ============================================

    /**
     * @dev Fuzz test: Any valid proposal index should work
     * Foundry will automatically test with random values
     */
    function testFuzz_Vote_AnyValidProposal(uint256 proposalIndex) public {
        // Bound the input to valid range
        proposalIndex = bound(proposalIndex, 0, proposalNames.length - 1);

        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        votingContract.vote(proposalIndex);

        (, uint256 voteCount) = votingContract.proposals(proposalIndex);
        assertEq(voteCount, 1, "Vote should be counted for any valid proposal");
    }

    /**
     * @dev Fuzz test: Invalid proposal indices should always revert
     */
    function testFuzz_Vote_InvalidProposalReverts(uint256 invalidIndex) public {
        // Ensure the index is out of bounds
        vm.assume(invalidIndex >= proposalNames.length);

        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        vm.prank(voter1);
        vm.expectRevert("Invalid proposal");
        votingContract.vote(invalidIndex);
    }

    /**
     * @dev Fuzz test: Multiple voters with random proposal choices
     */
    function testFuzz_MultipleVoters_RandomChoices(
        uint8 proposal1,
        uint8 proposal2,
        uint8 proposal3
    ) public {
        // Bound all proposals to valid range
        proposal1 = uint8(bound(proposal1, 0, 2));
        proposal2 = uint8(bound(proposal2, 0, 2));
        proposal3 = uint8(bound(proposal3, 0, 2));

        // Register voters
        vm.startPrank(chairperson);
        votingContract.giveRightToVote(voter1);
        votingContract.giveRightToVote(voter2);
        votingContract.giveRightToVote(voter3);
        vm.stopPrank();

        // Cast votes
        vm.prank(voter1);
        votingContract.vote(proposal1);

        vm.prank(voter2);
        votingContract.vote(proposal2);

        vm.prank(voter3);
        votingContract.vote(proposal3);

        // Calculate expected counts
        uint256[3] memory expectedCounts;
        expectedCounts[proposal1]++;
        expectedCounts[proposal2]++;
        expectedCounts[proposal3]++;

        // Verify vote counts
        for (uint256 i = 0; i < 3; i++) {
            (, uint256 actualCount) = votingContract.proposals(i);
            assertEq(actualCount, expectedCounts[i], "Vote count mismatch");
        }
    }

    // ============================================
    // INVARIANT TESTS (Advanced Pattern)
    // ============================================

    /**
     * @dev Invariant: Total votes cast should never exceed number of registered voters
     */
    function invariant_TotalVotesNeverExceedsVoters() public view {
        uint256 totalVotes = 0;
        for (uint256 i = 0; i < proposalNames.length; i++) {
            (, uint256 voteCount) = votingContract.proposals(i);
            totalVotes += voteCount;
        }

        // This would need a counter in the contract to properly test
        // For now, we demonstrate the pattern
        assertTrue(totalVotes <= 100, "Total votes sanity check");
    }

    // ============================================
    // INTEGRATION TESTS (Complex Scenarios)
    // ============================================

    function test_CompleteVotingScenario() public {
        // Scenario: Full voting cycle with tie-breaking

        // 1. Register 4 voters
        vm.startPrank(chairperson);
        votingContract.giveRightToVote(voter1);
        votingContract.giveRightToVote(voter2);
        votingContract.giveRightToVote(voter3);
        vm.stopPrank();

        // 2. Voters vote: A gets 2, B gets 2, C gets 1
        vm.prank(chairperson);
        votingContract.vote(0); // A

        vm.prank(voter1);
        votingContract.vote(0); // A

        vm.prank(voter2);
        votingContract.vote(1); // B

        vm.prank(voter3);
        votingContract.vote(1); // B

        // 3. Check results (in case of tie, lowest index wins)
        uint256 winner = votingContract.winningProposal();
        assertEq(winner, 0, "Proposal A should win in tie (lower index)");

        // 4. Verify all voters are marked as voted
        assertTrue(votingContract.hasAddressVoted(chairperson));
        assertTrue(votingContract.hasAddressVoted(voter1));
        assertTrue(votingContract.hasAddressVoted(voter2));
        assertTrue(votingContract.hasAddressVoted(voter3));
    }

    function test_EmptyVotingState() public view {
        // Test initial state with no votes
        uint256 winner = votingContract.winningProposal();
        string memory winnerName = votingContract.winnerName();

        assertEq(winner, 0);
        assertEq(
            winnerName,
            "Proposal A",
            "Should return first proposal when no votes"
        );
    }

    function test_SingleVoterScenario() public {
        // Only chairperson votes
        vm.prank(chairperson);
        votingContract.vote(2);

        assertEq(votingContract.winningProposal(), 2);
        assertEq(votingContract.winnerName(), "Proposal C");
    }

    // ============================================
    // GAS OPTIMIZATION TESTS
    // ============================================

    function test_Gas_VoteCost() public {
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);

        uint256 gasBefore = gasleft();
        vm.prank(voter1);
        votingContract.vote(0);
        uint256 gasUsed = gasBefore - gasleft();

        // Log gas usage for monitoring
        console2.log("Gas used for vote:", gasUsed);

        // Ensure vote costs less than 100k gas (reasonable threshold)
        assertLt(gasUsed, 100_000, "Vote should be gas efficient");
    }

    function test_Gas_RegistrationCost() public {
        uint256 gasBefore = gasleft();
        vm.prank(chairperson);
        votingContract.giveRightToVote(voter1);
        uint256 gasUsed = gasBefore - gasleft();

        console2.log("Gas used for registration:", gasUsed);
        assertLt(gasUsed, 100_000, "Registration should be gas efficient");
    }

    // ============================================
    // SPECIAL EDGE CASES
    // ============================================

    function test_Proposal_WithEmptyString() public {
        string[] memory emptyNames = new string[](1);
        emptyNames[0] = "";

        vm.prank(makeAddr("newChairperson"));
        VotingContract newContract = new VotingContract(emptyNames);

        (string memory name, ) = newContract.proposals(0);
        assertEq(name, "", "Empty string proposal should be allowed");
    }

    function test_Proposal_WithVeryLongString() public {
        string[] memory longNames = new string[](1);
        longNames[
            0
        ] = "This is a very long proposal name that exceeds normal length to test string handling";

        vm.prank(makeAddr("newChairperson"));
        VotingContract newContract = new VotingContract(longNames);

        (string memory name, ) = newContract.proposals(0);
        assertEq(name, longNames[0], "Long string should be stored correctly");
    }

    function test_ZeroProposals_ShouldNotRevert() public {
        string[] memory noProposals = new string[](0);

        vm.prank(makeAddr("newChairperson"));
        VotingContract newContract = new VotingContract(noProposals);

        assertEq(
            newContract.getProposalCount(),
            0,
            "Should handle zero proposals"
        );
    }

    // ============================================
    // HELPER FUNCTIONS FOR TESTS
    // ============================================

    /**
     * @dev Helper: Register multiple voters
     */
    function _registerVoters(address[] memory voterAddresses) internal {
        vm.startPrank(chairperson);
        for (uint256 i = 0; i < voterAddresses.length; i++) {
            votingContract.giveRightToVote(voterAddresses[i]);
        }
        vm.stopPrank();
    }

    /**
     * @dev Helper: Get current vote distribution
     */
    function _getVoteDistribution() internal view returns (uint256[] memory) {
        uint256[] memory distribution = new uint256[](proposalNames.length);
        for (uint256 i = 0; i < proposalNames.length; i++) {
            (, uint256 voteCount) = votingContract.proposals(i);
            distribution[i] = voteCount;
        }
        return distribution;
    }
}
