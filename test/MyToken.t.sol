// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

/**
 * @title MyToken Test Suite
 * @notice Comprehensive tests for the MyToken ERC20 implementation
 */
contract MyTokenTest is Test {
    // ===== TEST SETUP =====
    MyToken public token;
    
    // Test accounts
    address public owner;
    address public alice;
    address public bob;
    address public charlie;
    
    uint256 constant INITIAL_SUPPLY = 1_000_000; // 1 million tokens
    uint256 constant DECIMALS = 18;
    
    // Events we'll test for (must match contract events)
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    /**
     * @notice Setup runs before EVERY test function
     * @dev This ensures each test starts with a clean slate
     */
    function setUp() public {
        // Create test accounts
        owner = address(this); // The test contract is the owner
        alice = makeAddr("alice"); // Foundry helper to create addresses
        bob = makeAddr("bob");
        charlie = makeAddr("charlie");
        
        // Deploy the token contract
        token = new MyToken(INITIAL_SUPPLY);
    }
    
    // ============================================
    // 📦 DEPLOYMENT & METADATA TESTS
    // ============================================
    
    function test_Deployment_InitialSupply() public {
        uint256 expectedSupply = INITIAL_SUPPLY * 10**DECIMALS;
        assertEq(token.totalSupply(), expectedSupply, "Total supply mismatch");
    }
    
    function test_Deployment_OwnerBalance() public {
        uint256 expectedBalance = INITIAL_SUPPLY * 10**DECIMALS;
        assertEq(token.balanceOf(owner), expectedBalance, "Owner should have all tokens");
    }
    
    function test_Deployment_Metadata() public {
        assertEq(token.name(), "AlanDXiang Coin", "Name mismatch");
        assertEq(token.symbol(), "ADX", "Symbol mismatch");
        assertEq(token.decimals(), 18, "Decimals mismatch");
    }
    
    // ============================================
    // 💸 TRANSFER TESTS
    // ============================================
    
    function test_Transfer_Success() public {
        uint256 amount = 100 * 10**DECIMALS;
        
        // Expect the Transfer event
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, alice, amount);
        
        // Perform transfer
        bool success = token.transfer(alice, amount);
        
        // Assertions
        assertTrue(success, "Transfer should return true");
        assertEq(token.balanceOf(alice), amount, "Alice should receive tokens");
        assertEq(token.balanceOf(owner), (INITIAL_SUPPLY * 10**DECIMALS) - amount, "Owner balance should decrease");
    }
    
    function test_Transfer_RevertWhen_InsufficientBalance() public {
        uint256 tooMuch = (INITIAL_SUPPLY + 1) * 10**DECIMALS;
        
        vm.expectRevert("Insufficient balance");
        token.transfer(alice, tooMuch);
    }
    
    function test_Transfer_RevertWhen_ZeroAddress() public {
        uint256 amount = 100 * 10**DECIMALS;
        
        vm.expectRevert("Cannot transfer to zero address");
        token.transfer(address(0), amount);
    }
    
    function test_Transfer_FromNonOwner() public {
        // First, give Alice some tokens
        uint256 amount = 100 * 10**DECIMALS;
        token.transfer(alice, amount);
        
        // Now Alice transfers to Bob
        vm.prank(alice); // Next call will be from Alice's address
        token.transfer(bob, 50 * 10**DECIMALS);
        
        assertEq(token.balanceOf(bob), 50 * 10**DECIMALS, "Bob should receive tokens");
        assertEq(token.balanceOf(alice), 50 * 10**DECIMALS, "Alice balance should decrease");
    }
    
    // ============================================
    // ✅ APPROVAL & ALLOWANCE TESTS
    // ============================================
    
    function test_Approve_Success() public {
        uint256 amount = 500 * 10**DECIMALS;
        
        // Expect the Approval event
        vm.expectEmit(true, true, false, true);
        emit Approval(owner, alice, amount);
        
        bool success = token.approve(alice, amount);
        
        assertTrue(success, "Approval should return true");
        assertEq(token.allowance(owner, alice), amount, "Allowance mismatch");
    }
    
    function test_Approve_RevertWhen_ZeroAddress() public {
        vm.expectRevert("Cannot approve zero address");
        token.approve(address(0), 100);
    }
    
    function test_Approve_Overwrite() public {
        // First approval
        token.approve(alice, 100 * 10**DECIMALS);
        
        // Second approval overwrites the first
        token.approve(alice, 200 * 10**DECIMALS);
        
        assertEq(token.allowance(owner, alice), 200 * 10**DECIMALS, "Second approval should overwrite");
    }
    
    // ============================================
    // 🔄 TRANSFERFROM TESTS
    // ============================================
    
    function test_TransferFrom_Success() public {
        uint256 amount = 100 * 10**DECIMALS;
        
        // Owner approves Alice to spend tokens
        token.approve(alice, amount);
        
        // Alice transfers from Owner to Bob
        vm.prank(alice);
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, bob, amount);
        
        bool success = token.transferFrom(owner, bob, amount);
        
        assertTrue(success, "TransferFrom should succeed");
        assertEq(token.balanceOf(bob), amount, "Bob should receive tokens");
        assertEq(token.allowance(owner, alice), 0, "Allowance should be reduced to 0");
    }
    
    function test_TransferFrom_RevertWhen_NoAllowance() public {
        uint256 amount = 100 * 10**DECIMALS;
        
        vm.prank(alice);
        vm.expectRevert("Allowance exceeded");
        token.transferFrom(owner, bob, amount);
    }
    
    function test_TransferFrom_RevertWhen_InsufficientAllowance() public {
        // Approve 50 tokens
        token.approve(alice, 50 * 10**DECIMALS);
        
        // Try to transfer 100 tokens
        vm.prank(alice);
        vm.expectRevert("Allowance exceeded");
        token.transferFrom(owner, bob, 100 * 10**DECIMALS);
    }
    
    function test_TransferFrom_RevertWhen_InsufficientBalance() public {
        // Give Alice only 50 tokens
        token.transfer(alice, 50 * 10**DECIMALS);
        
        // Alice approves Bob to spend 100 tokens (more than she has)
        vm.prank(alice);
        token.approve(bob, 100 * 10**DECIMALS);
        
        // Bob tries to transfer 100 from Alice
        vm.prank(bob);
        vm.expectRevert("Insufficient balance");
        token.transferFrom(alice, charlie, 100 * 10**DECIMALS);
    }
    
    // ============================================
    // ➕➖ INCREASE/DECREASE ALLOWANCE TESTS
    // ============================================
    
    function test_IncreaseAllowance_Success() public {
        // Initial approval
        token.approve(alice, 100 * 10**DECIMALS);
        
        // Increase allowance
        token.increaseAllowance(alice, 50 * 10**DECIMALS);
        
        assertEq(token.allowance(owner, alice), 150 * 10**DECIMALS, "Allowance should increase");
    }
    
    function test_DecreaseAllowance_Success() public {
        // Initial approval
        token.approve(alice, 100 * 10**DECIMALS);
        
        // Decrease allowance
        token.decreaseAllowance(alice, 30 * 10**DECIMALS);
        
        assertEq(token.allowance(owner, alice), 70 * 10**DECIMALS, "Allowance should decrease");
    }
    
    function test_DecreaseAllowance_RevertWhen_BelowZero() public {
        token.approve(alice, 50 * 10**DECIMALS);
        
        vm.expectRevert("Decreased allowance below zero");
        token.decreaseAllowance(alice, 100 * 10**DECIMALS);
    }
    
    // ============================================
    // 🔥 BURN TESTS
    // ============================================
    
    function test_Burn_Success() public {
        uint256 burnAmount = 100 * 10**DECIMALS;
        uint256 initialSupply = token.totalSupply();
        uint256 initialBalance = token.balanceOf(owner);
        
        vm.expectEmit(true, true, false, true);
        emit Transfer(owner, address(0), burnAmount);
        
        bool success = token.burn(burnAmount);
        
        assertTrue(success, "Burn should succeed");
        assertEq(token.balanceOf(owner), initialBalance - burnAmount, "Balance should decrease");
        assertEq(token.totalSupply(), initialSupply - burnAmount, "Total supply should decrease");
    }
    
    function test_Burn_RevertWhen_InsufficientBalance() public {
        uint256 tooMuch = (INITIAL_SUPPLY + 1) * 10**DECIMALS;
        
        vm.expectRevert("Insufficient balance to burn");
        token.burn(tooMuch);
    }
    
    // ============================================
    // 🎲 FUZZ TESTS (Foundry's Superpower!)
    // ============================================
    
    /**
     * @notice Fuzz test: Transfer any valid amount
     * @dev Foundry will automatically test with random inputs
     */
    function testFuzz_Transfer(uint256 amount) public {
        // Bound the amount to valid range
        amount = bound(amount, 0, token.balanceOf(owner));
        
        token.transfer(alice, amount);
        
        assertEq(token.balanceOf(alice), amount);
    }
    
    /**
     * @notice Fuzz test: TransferFrom with random allowances
     */
    function testFuzz_TransferFrom(uint256 allowanceAmount, uint256 transferAmount) public {
        // Ensure valid test parameters
        allowanceAmount = bound(allowanceAmount, 1, token.balanceOf(owner));
        transferAmount = bound(transferAmount, 1, allowanceAmount);
        
        // Setup
        token.approve(alice, allowanceAmount);
        
        // Execute
        vm.prank(alice);
        token.transferFrom(owner, bob, transferAmount);
        
        // Verify
        assertEq(token.balanceOf(bob), transferAmount);
        assertEq(token.allowance(owner, alice), allowanceAmount - transferAmount);
    }
    
    // ============================================
    // 🔐 INVARIANT TESTS (Advanced!)
    // ============================================
    
    /**
     * @notice Invariant: Total supply should never change (except through burn)
     */
    function invariant_TotalSupplyConstant() public {
        // This test runs after random sequences of function calls
        uint256 currentSupply = token.totalSupply();
        assertTrue(currentSupply <= INITIAL_SUPPLY * 10**DECIMALS, "Supply should never increase");
    }
}
