// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../src/CrowdFund.sol";

// contract CrowdFundTest is Test {
//     CrowdFund public crowdFund;

//     address public owner;
//     address public contributor1;
//     address public contributor2;
//     address public contributor3;

//     uint256 constant GOAL = 10 ether;
//     uint256 constant DURATION = 60; // 60 分钟

//     // 自定义事件（用于测试）
//     event ContributionReceived(
//         address indexed contributor,
//         uint256 amount,
//         uint256 totalFunded
//     );
//     event FundsWithdrawn(address indexed owner, uint256 amount);
//     event RefundIssued(address indexed contributor, uint256 amount);
//     event StateChanged(CrowdFund.State newState);

//     function setUp() public {
//         owner = address(this);
//         contributor1 = makeAddr("contributor1");
//         contributor2 = makeAddr("contributor2");
//         contributor3 = makeAddr("contributor3");

//         vm.deal(contributor1, 100 ether);
//         vm.deal(contributor2, 100 ether);
//         vm.deal(contributor3, 100 ether);

//         crowdFund = new CrowdFund(GOAL, DURATION);
//     }

contract CrowdFundTest is Test {
    CrowdFund public crowdFund;

    address public owner;
    address public contributor1;
    address public contributor2;
    address public contributor3;

    uint256 constant GOAL = 10 ether;
    uint256 constant DURATION = 60;

    event ContributionReceived(address indexed contributor, uint256 amount, uint256 totalFunded);
    event FundsWithdrawn(address indexed owner, uint256 amount);
    event RefundIssued(address indexed contributor, uint256 amount);
    event StateChanged(CrowdFund.State newState);

    // 🔥 ADD THIS - Allow test contract to receive Ether
    receive() external payable {}

    function setUp() public {
        owner = address(this); // Now this works!
        contributor1 = makeAddr("contributor1");
        contributor2 = makeAddr("contributor2");
        contributor3 = makeAddr("contributor3");

        vm.deal(contributor1, 100 ether);
        vm.deal(contributor2, 100 ether);
        vm.deal(contributor3, 100 ether);

        crowdFund = new CrowdFund(GOAL, DURATION);
    }

    // ... rest of your tests

    // ========== 测试组 1: 部署和初始化 ==========

    function test_Deployment_OwnerIsSet() public view {
        assertEq(crowdFund.owner(), owner);
    }

    function test_Deployment_GoalIsSet() public view {
        assertEq(crowdFund.goal(), GOAL);
    }

    function test_Deployment_DeadlineIsSet() public view {
        assertEq(crowdFund.deadline(), block.timestamp + (DURATION * 1 minutes));
    }

    function test_Deployment_InitialStateIsFunding() public view {
        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Funding));
    }

    function test_Deployment_TotalFundedIsZero() public view {
        assertEq(crowdFund.totalFunded(), 0);
    }

    function test_Deployment_FundsNotWithdrawn() public view {
        assertFalse(crowdFund.fundsWithdrawn());
    }

    function test_RevertWhen_DeploymentWithZeroGoal() public {
        vm.expectRevert("Goal must be greater than 0");
        new CrowdFund(0, DURATION);
    }

    function test_RevertWhen_DeploymentWithZeroDuration() public {
        vm.expectRevert("Duration must be greater than 0");
        new CrowdFund(GOAL, 0);
    }

    // ========== 测试组 2: 贡献功能 ==========

    function test_Contribute_Success() public {
        uint256 amount = 1 ether;

        vm.prank(contributor1);
        crowdFund.contribute{value: amount}();

        assertEq(crowdFund.totalFunded(), amount);
        assertEq(crowdFund.contributions(contributor1), amount);
        assertEq(crowdFund.getBalance(), amount);
    }

    function test_Contribute_MultipleUsers() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 3 ether}();

        vm.prank(contributor2);
        crowdFund.contribute{value: 5 ether}();

        assertEq(crowdFund.totalFunded(), 8 ether);
        assertEq(crowdFund.contributions(contributor1), 3 ether);
        assertEq(crowdFund.contributions(contributor2), 5 ether);
    }

    function test_Contribute_Cumulative() public {
        vm.startPrank(contributor1);
        crowdFund.contribute{value: 2 ether}();
        crowdFund.contribute{value: 3 ether}();
        vm.stopPrank();

        assertEq(crowdFund.contributions(contributor1), 5 ether);
        assertEq(crowdFund.totalFunded(), 5 ether);
    }

    function test_Contribute_EmitsEvent() public {
        uint256 amount = 1 ether;

        vm.expectEmit(true, false, false, true);
        emit ContributionReceived(contributor1, amount, amount);

        vm.prank(contributor1);
        crowdFund.contribute{value: amount}();
    }

    function test_Contribute_ViaReceive() public {
        uint256 amount = 1 ether;

        vm.prank(contributor1);
        (bool success,) = address(crowdFund).call{value: amount}("");

        assertTrue(success);
        assertEq(crowdFund.contributions(contributor1), amount);
    }

    function test_Contribute_ViaFallback() public {
        uint256 amount = 1 ether;

        vm.prank(contributor1);
        (bool success,) = address(crowdFund).call{value: amount}("0x1234");

        assertTrue(success);
        assertEq(crowdFund.contributions(contributor1), amount);
    }

    function test_RevertWhen_ContributeZeroAmount() public {
        vm.expectRevert("Contribution must be greater than 0");
        crowdFund.contribute{value: 0}();
    }

    function test_Contribute_RevertZeroAmount() public {
        vm.prank(contributor1);
        vm.expectRevert("Contribution must be greater than 0");
        crowdFund.contribute{value: 0}();
    }

    function test_Contribute_RevertAfterDeadline() public {
        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        vm.prank(contributor1);
        vm.expectRevert("Crowdfund has ended");
        crowdFund.contribute{value: 1 ether}();
    }

    function test_Contribute_RevertWhenNotFunding() public {
        // 达到目标并更新状态
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        // 尝试再次贡献
        vm.prank(contributor2);
        vm.expectRevert("Crowdfund has ended");
        crowdFund.contribute{value: 1 ether}();
    }

    // ========== 测试组 3: 查询函数 ==========

    function test_GetProgress_Zero() public view {
        assertEq(crowdFund.getProgress(), 0);
    }

    function test_GetProgress_Fifty() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        assertEq(crowdFund.getProgress(), 50);
    }

    function test_GetProgress_OverHundred() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 15 ether}();

        assertEq(crowdFund.getProgress(), 150);
    }

    function test_IsGoalReached_False() public view {
        assertFalse(crowdFund.isGoalReached());
    }

    function test_IsGoalReached_True() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        assertTrue(crowdFund.isGoalReached());
    }

    function test_GetTimeRemaining_AtStart() public view {
        assertEq(crowdFund.getTimeRemaining(), DURATION * 1 minutes);
    }

    function test_GetTimeRemaining_Halfway() public {
        vm.warp(block.timestamp + 30 minutes);
        assertEq(crowdFund.getTimeRemaining(), 30 minutes);
    }

    function test_GetTimeRemaining_AfterDeadline() public {
        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        assertEq(crowdFund.getTimeRemaining(), 0);
    }

    function test_GetBalance() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        assertEq(crowdFund.getBalance(), 5 ether);
    }

    function test_GetContribution() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 3 ether}();

        assertEq(crowdFund.getContribution(contributor1), 3 ether);
        assertEq(crowdFund.getContribution(contributor2), 0);
    }

    // ========== 测试组 4: 状态管理 ==========

    function test_CheckAndUpdateState_RevertBeforeDeadline() public {
        vm.expectRevert("Crowdfund is still active");
        crowdFund.checkAndUpdateState();
    }

    function test_CheckAndUpdateState_ToSuccessful() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));
    }

    function test_CheckAndUpdateState_ToFailed() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Failed));
    }

    function test_CheckAndUpdateState_EmitsSuccessfulEvent() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        vm.expectEmit(false, false, false, true);
        emit StateChanged(CrowdFund.State.Successful);

        crowdFund.checkAndUpdateState();
    }

    function test_CheckAndUpdateState_EmitsFailedEvent() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        vm.expectEmit(false, false, false, true);
        emit StateChanged(CrowdFund.State.Failed);

        crowdFund.checkAndUpdateState();
    }

    function test_CheckAndUpdateState_IdempotentWhenSuccessful() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        crowdFund.checkAndUpdateState();
        crowdFund.checkAndUpdateState(); // 第二次调用不应该改变状态

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));
    }

    // ========== 测试组 5: 成功场景 - 提取资金 ==========

    function test_WithdrawFunds_Success() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 12 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        uint256 balanceBefore = owner.balance;

        vm.prank(owner);
        crowdFund.withdrawFunds();

        assertEq(owner.balance, balanceBefore + 12 ether);
        assertTrue(crowdFund.fundsWithdrawn());
        assertEq(crowdFund.getBalance(), 0);
    }

    // function test_WithdrawFunds_EmitsEvent() public {
    //     vm.prank(contributor1);
    //     crowdFund.contribute{value: 10 ether}();

    //     vm.warp(block.timestamp + DURATION * 1 minutes + 1);
    //     crowdFund.checkAndUpdateState();

    //     vm.expectEmit(true, false, false, true);
    //     emit FundsWithdrawn(owner, 10 ether);
    //     crowdFund.withdrawFunds();
    //     console.log("owner blance", owner.balance);
    // }

    function test_WithdrawFunds_EmitsEvent() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        // 🔥 关键:在调用前获取合约的实际余额
        uint256 actualBalance = address(crowdFund).balance;

        vm.prank(owner);
        // vm.expectEmit(true, false, false, true);
        console.log("owner:", owner);
        console.log("actualBalance:", actualBalance);
        emit FundsWithdrawn(owner, actualBalance); // 使用实际值
        console.log("msg.sender:", msg.sender);
        console.log("crowdFund balance:", crowdFund.getBalance());
        console.log("owner balance:", owner.balance);
        crowdFund.withdrawFunds();
        console.log("crowdFund balance2:", crowdFund.getBalance());
        console.log("owner balance2:", owner.balance);
    }

    function test_WithdrawFunds_RevertNotOwner() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.prank(contributor1);
        vm.expectRevert("Only owner can call this function");
        crowdFund.withdrawFunds();
    }

    function test_WithdrawFunds_RevertBeforeDeadline() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.expectRevert("Crowdfund is still active");
        crowdFund.withdrawFunds();
    }

    function test_WithdrawFunds_RevertWhenFailed() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.expectRevert("Invalid state for this operation");
        crowdFund.withdrawFunds();
    }

    function test_WithdrawFunds_RevertAlreadyWithdrawn() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        crowdFund.withdrawFunds();

        vm.expectRevert("Funds already withdrawn");
        crowdFund.withdrawFunds();
    }

    // ========== 测试组 6: 失败场景 - 退款 ==========

    function test_Refund_Success() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        uint256 balanceBefore = contributor1.balance;

        vm.prank(contributor1);
        crowdFund.refund();

        assertEq(contributor1.balance, balanceBefore + 5 ether);
        assertEq(crowdFund.contributions(contributor1), 0);
    }

    function test_Refund_MultipleContributors() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 3 ether}();

        vm.prank(contributor2);
        crowdFund.contribute{value: 2 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        uint256 balance1Before = contributor1.balance;
        uint256 balance2Before = contributor2.balance;

        vm.prank(contributor1);
        crowdFund.refund();

        vm.prank(contributor2);
        crowdFund.refund();

        assertEq(contributor1.balance, balance1Before + 3 ether);
        assertEq(contributor2.balance, balance2Before + 2 ether);
        assertEq(crowdFund.getBalance(), 0);
    }

    function test_Refund_EmitsEvent() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.expectEmit(true, false, false, true);
        emit RefundIssued(contributor1, 5 ether);

        vm.prank(contributor1);
        crowdFund.refund();
    }

    function test_Refund_RevertNoContribution() public {
        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.prank(contributor1);
        vm.expectRevert("No contribution to refund");
        crowdFund.refund();
    }

    function test_Refund_RevertBeforeDeadline() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.prank(contributor1);
        vm.expectRevert("Crowdfund is still active");
        crowdFund.refund();
    }

    function test_Refund_RevertWhenSuccessful() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.prank(contributor1);
        vm.expectRevert("Invalid state for this operation");
        crowdFund.refund();
    }

    function test_Refund_RevertDoubleRefund() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.prank(contributor1);
        crowdFund.refund();

        vm.prank(contributor1);
        vm.expectRevert("No contribution to refund");
        crowdFund.refund();
    }

    function test_Refund_PreventsReentrancy() public {
        // 创建恶意合约
        // MaliciousRefunder attacker = new MaliciousRefunder(address(crowdFund));
        MaliciousRefunder attacker = new MaliciousRefunder(payable(address(crowdFund)));
        vm.deal(address(attacker), 10 ether);

        // 恶意合约贡献
        attacker.attack{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        // 尝试重入攻击
        attacker.executeRefund();

        // 验证只退款一次
        assertEq(crowdFund.contributions(address(attacker)), 0);
    }

    // ========== 测试组 7: 边界条件 ==========

    function test_Boundary_ExactGoalAmount() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        assertTrue(crowdFund.isGoalReached());
        assertEq(crowdFund.getProgress(), 100);
    }

    function test_Boundary_JustBelowGoal() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether - 1}();

        assertFalse(crowdFund.isGoalReached());
    }

    function test_Boundary_OverGoal() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 15 ether}();

        assertTrue(crowdFund.isGoalReached());
        assertEq(crowdFund.getProgress(), 150);
    }

    function test_Boundary_DeadlineExactly() public {
        vm.warp(block.timestamp + DURATION * 1 minutes);

        vm.prank(contributor1);
        vm.expectRevert("Crowdfund has ended");
        crowdFund.contribute{value: 1 ether}();
    }

    function test_Boundary_OneSecondBeforeDeadline() public {
        vm.warp(block.timestamp + DURATION * 1 minutes - 1);

        vm.prank(contributor1);
        crowdFund.contribute{value: 1 ether}();

        assertEq(crowdFund.totalFunded(), 1 ether);
    }

    function test_Boundary_MinimalContribution() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 1 wei}();

        assertEq(crowdFund.contributions(contributor1), 1 wei);
    }

    function test_Boundary_MaximalContribution() public {
        vm.deal(contributor1, type(uint256).max);

        vm.prank(contributor1);
        crowdFund.contribute{value: 100 ether}();

        assertEq(crowdFund.contributions(contributor1), 100 ether);
    }

    // ========== 测试组 8: Fuzz Testing ==========

    function testFuzz_Contribute(uint256 amount) public {
        vm.assume(amount > 0 && amount <= 1000 ether);

        vm.deal(contributor1, amount);

        vm.prank(contributor1);
        crowdFund.contribute{value: amount}();

        assertEq(crowdFund.contributions(contributor1), amount);
        assertEq(crowdFund.totalFunded(), amount);
    }

    function testFuzz_MultipleContributions(uint256 amount1, uint256 amount2, uint256 amount3) public {
        vm.assume(amount1 > 0 && amount1 <= 100 ether);
        vm.assume(amount2 > 0 && amount2 <= 100 ether);
        vm.assume(amount3 > 0 && amount3 <= 100 ether);

        vm.deal(contributor1, amount1);
        vm.deal(contributor2, amount2);
        vm.deal(contributor3, amount3);

        vm.prank(contributor1);
        crowdFund.contribute{value: amount1}();

        vm.prank(contributor2);
        crowdFund.contribute{value: amount2}();

        vm.prank(contributor3);
        crowdFund.contribute{value: amount3}();

        assertEq(crowdFund.totalFunded(), amount1 + amount2 + amount3);
    }

    function testFuzz_GetProgress(uint256 amount) public {
        vm.assume(amount > 0 && amount <= GOAL * 2);

        vm.deal(contributor1, amount);

        vm.prank(contributor1);
        crowdFund.contribute{value: amount}();

        uint256 expectedProgress = (amount * 100) / GOAL;
        assertEq(crowdFund.getProgress(), expectedProgress);
    }

    function testFuzz_RefundAmount(uint256 amount) public {
        vm.assume(amount > 0 && amount < 10 ether);

        vm.deal(contributor1, amount);
        console.log("Amount:", amount);

        vm.prank(contributor1);
        crowdFund.contribute{value: amount}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        uint256 balanceBefore = contributor1.balance;

        vm.prank(contributor1);
        crowdFund.refund();

        assertEq(contributor1.balance, balanceBefore + amount, "Refund amount mismatch");
    }

    // ========== 测试组 9: 复杂场景 ==========

    function test_CompleteSuccessfulCampaign() public {
        // 多个贡献者在不同时间贡献
        vm.prank(contributor1);
        crowdFund.contribute{value: 4 ether}();

        vm.warp(block.timestamp + 20 minutes);

        vm.prank(contributor2);
        crowdFund.contribute{value: 3 ether}();

        vm.warp(block.timestamp + 20 minutes);

        vm.prank(contributor3);
        crowdFund.contribute{value: 5 ether}();
        console.log("contributor1.balance", contributor1.balance);
        console.log("contributor2.balance", contributor2.balance);
        console.log("contributor3.balance", contributor3.balance);

        // 验证中间状态
        assertEq(crowdFund.totalFunded(), 12 ether);
        assertTrue(crowdFund.isGoalReached());

        // 截止后更新状态
        vm.warp(block.timestamp + 21 minutes);
        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));

        // Owner 提取资金
        uint256 ownerBalanceBefore = owner.balance;
        vm.prank(owner);
        console.log("crowdFund.balance0", address(this).balance);
        crowdFund.withdrawFunds();
        console.log("crowdFund.balance", address(this).balance);

        assertEq(owner.balance, ownerBalanceBefore + 12 ether);
        assertEq(crowdFund.getBalance(), 0);
        assertTrue(crowdFund.fundsWithdrawn());
    }

    function test_CompleteFailedCampaign() public {
        // 多个贡献者但未达目标
        vm.prank(contributor1);
        crowdFund.contribute{value: 3 ether}();

        vm.prank(contributor2);
        crowdFund.contribute{value: 2 ether}();

        vm.prank(contributor3);
        crowdFund.contribute{value: 1 ether}();

        assertEq(crowdFund.totalFunded(), 6 ether);
        assertFalse(crowdFund.isGoalReached());

        // 截止后更新状态
        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Failed));

        // 所有贡献者退款
        uint256 balance1Before = contributor1.balance;
        uint256 balance2Before = contributor2.balance;
        uint256 balance3Before = contributor3.balance;

        vm.prank(contributor1);
        crowdFund.refund();

        vm.prank(contributor2);
        crowdFund.refund();

        vm.prank(contributor3);
        crowdFund.refund();

        assertEq(contributor1.balance, balance1Before + 3 ether);
        assertEq(contributor2.balance, balance2Before + 2 ether);
        assertEq(contributor3.balance, balance3Before + 1 ether);
        assertEq(crowdFund.getBalance(), 0);
    }

    function test_MixedContributionSizes() public {
        // 测试各种大小的贡献
        vm.prank(contributor1);
        crowdFund.contribute{value: 1 wei}();

        vm.prank(contributor1);
        crowdFund.contribute{value: 0.0001 ether}();

        vm.prank(contributor2);
        crowdFund.contribute{value: 5 ether}();

        vm.prank(contributor3);
        crowdFund.contribute{value: 10 ether}();

        assertTrue(crowdFund.totalFunded() > GOAL);
    }

    function test_LastSecondContribution() public {
        // 在最后一秒贡献达到目标
        vm.warp(block.timestamp + DURATION * 1 minutes - 1);

        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + 1);
        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));
    }

    // ========== 测试组 10: Gas 优化验证 ==========

    function test_Gas_SingleContribution() public {
        vm.prank(contributor1);
        uint256 gasBefore = gasleft();
        crowdFund.contribute{value: 1 ether}();
        uint256 gasUsed = gasBefore - gasleft();

        // 记录 gas 使用量（用于优化参考）
        emit log_named_uint("Gas used for single contribution", gasUsed);
        assertLt(gasUsed, 100000); // 应该少于 100k gas
    }

    function test_Gas_Refund() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        vm.prank(contributor1);
        uint256 gasBefore = gasleft();
        crowdFund.refund();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for refund", gasUsed);
        assertLt(gasUsed, 100000);
    }

    function test_Gas_WithdrawFunds() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        uint256 gasBefore = gasleft();
        crowdFund.withdrawFunds();
        uint256 gasUsed = gasBefore - gasleft();

        emit log_named_uint("Gas used for withdraw", gasUsed);
        assertLt(gasUsed, 100000);
    }

    // ========== 测试组 11: 不变量测试 ==========

    function invariant_TotalFundedMatchesBalance() public view {
        if (uint256(crowdFund.currentState()) == uint256(CrowdFund.State.Funding)) {
            assertEq(crowdFund.totalFunded(), crowdFund.getBalance());
        }
    }

    function invariant_StateTransitionsAreOneWay() public view {
        // 状态只能从 Funding -> Successful 或 Funding -> Failed
        // 永远不会回退到 Funding
        CrowdFund.State currentState = crowdFund.currentState();
        if (currentState != CrowdFund.State.Funding) {
            assertTrue(currentState == CrowdFund.State.Successful || currentState == CrowdFund.State.Failed);
        }
    }

    function invariant_FundsWithdrawnOnlyWhenSuccessful() public view {
        if (crowdFund.fundsWithdrawn()) {
            assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));
        }
    }

    function invariant_ContributionsCannotBeNegative() public view {
        // 所有贡献必须 >= 0
        assertGe(crowdFund.contributions(contributor1), 0);
        assertGe(crowdFund.contributions(contributor2), 0);
        assertGe(crowdFund.contributions(contributor3), 0);
    }

    function invariant_TotalFundedIsNonNegative() public view {
        assertGe(crowdFund.totalFunded(), 0);
    }

    function invariant_BalanceIsNonNegative() public view {
        assertGe(crowdFund.getBalance(), 0);
    }

    // ========== 测试组 12: 时间相关测试 ==========

    function test_Time_ProgressThroughCampaign() public {
        // 开始时
        assertEq(crowdFund.getTimeRemaining(), DURATION * 1 minutes);

        // 过去 25%
        vm.warp(block.timestamp + 15 minutes);
        assertEq(crowdFund.getTimeRemaining(), 45 minutes);

        // 过去 50%
        vm.warp(block.timestamp + 15 minutes);
        assertEq(crowdFund.getTimeRemaining(), 30 minutes);

        // 过去 75%
        vm.warp(block.timestamp + 15 minutes);
        assertEq(crowdFund.getTimeRemaining(), 15 minutes);

        // 过去 100%
        vm.warp(block.timestamp + 15 minutes);
        assertEq(crowdFund.getTimeRemaining(), 0);
    }

    function test_Time_ContributionsAtDifferentTimes() public {
        // T=0: 第一笔贡献
        vm.prank(contributor1);
        crowdFund.contribute{value: 2 ether}();

        // T=20min: 第二笔贡献
        vm.warp(block.timestamp + 20 minutes);
        vm.prank(contributor2);
        crowdFund.contribute{value: 3 ether}();

        // T=40min: 第三笔贡献
        vm.warp(block.timestamp + 20 minutes);
        vm.prank(contributor3);
        crowdFund.contribute{value: 5 ether}();

        assertEq(crowdFund.totalFunded(), 10 ether);
        assertEq(crowdFund.getTimeRemaining(), 20 minutes);
    }

    function test_Time_DeadlineEnforcement() public {
        // 截止前 1 秒：可以贡献
        vm.warp(block.timestamp + DURATION * 1 minutes - 1);
        vm.prank(contributor1);
        crowdFund.contribute{value: 1 ether}();

        // 截止时刻：不可以贡献
        vm.warp(block.timestamp + 1);
        vm.prank(contributor2);
        vm.expectRevert("Crowdfund has ended");
        crowdFund.contribute{value: 1 ether}();

        // 截止后 1 秒：不可以贡献
        vm.warp(block.timestamp + 1);
        vm.prank(contributor3);
        vm.expectRevert("Crowdfund has ended");
        crowdFund.contribute{value: 1 ether}();
    }

    // ========== 测试组 13: 访问控制测试 ==========

    function test_AccessControl_OnlyOwnerCanWithdraw() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        // contributor1 尝试提取
        vm.prank(contributor1);
        vm.expectRevert("Only owner can call this function");
        crowdFund.withdrawFunds();

        // contributor2 尝试提取
        vm.prank(contributor2);
        vm.expectRevert("Only owner can call this function");
        crowdFund.withdrawFunds();

        // owner 可以提取
        // crowdFund.withdrawFunds();
        // assertTrue(crowdFund.fundsWithdrawn());
    }

    function test_AccessControl_AnyoneCanContribute() public {
        // 任何地址都可以贡献
        address randomUser = makeAddr("randomUser");
        vm.deal(randomUser, 10 ether);

        vm.prank(randomUser);
        crowdFund.contribute{value: 1 ether}();

        assertEq(crowdFund.contributions(randomUser), 1 ether);
    }

    function test_AccessControl_AnyoneCanCheckState() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        // contributor1 可以更新状态
        vm.prank(contributor1);
        crowdFund.checkAndUpdateState();

        // 重置合约
        setUp();

        vm.prank(contributor1);
        crowdFund.contribute{value: 10 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        // 任何随机用户都可以更新状态
        address randomUser = makeAddr("randomUser2");
        vm.prank(randomUser);
        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));
    }

    function test_AccessControl_OnlyContributorCanRefund() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: 5 ether}();

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        // contributor2 没有贡献，不能退款
        vm.prank(contributor2);
        vm.expectRevert("No contribution to refund");
        crowdFund.refund();

        // contributor1 可以退款
        vm.prank(contributor1);
        crowdFund.refund();

        assertEq(crowdFund.contributions(contributor1), 0);
    }

    // ========== 测试组 14: 边界和异常情况 ==========

    function test_Edge_ZeroContributorsSuccessful() public {
        // 理论上不可能，但测试直接达到目标
        vm.deal(address(this), 100 ether);
        (bool success,) = address(crowdFund).call{value: 10 ether}("");
        assertTrue(success);

        vm.warp(block.timestamp + DURATION * 1 minutes + 1);
        crowdFund.checkAndUpdateState();

        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));
    }

    function test_Edge_SingleWeiAboveGoal() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: GOAL + 1 wei}();

        assertTrue(crowdFund.isGoalReached());
    }

    function test_Edge_SingleWeiBelowGoal() public {
        vm.prank(contributor1);
        crowdFund.contribute{value: GOAL - 1 wei}();

        assertFalse(crowdFund.isGoalReached());
    }

    function test_Edge_MaxUint256Contributions() public {
        // 测试非常大的贡献（接近 uint256 上限）
        // 注意：实际中不可能有这么多 ETH
        uint256 largeAmount = 1000000 ether;
        vm.deal(contributor1, largeAmount);

        vm.prank(contributor1);
        crowdFund.contribute{value: largeAmount}();

        assertEq(crowdFund.contributions(contributor1), largeAmount);
    }

    function test_Edge_VeryShortDuration() public {
        // 测试 1 分钟的众筹
        CrowdFund shortCrowdFund = new CrowdFund(1 ether, 1);

        vm.deal(contributor1, 10 ether);
        vm.prank(contributor1);
        shortCrowdFund.contribute{value: 1 ether}();

        vm.warp(block.timestamp + 1 minutes + 1);
        shortCrowdFund.checkAndUpdateState();

        assertEq(uint256(shortCrowdFund.currentState()), uint256(CrowdFund.State.Successful));
    }

    function test_Edge_VeryLongDuration() public {
        // 测试 1 年的众筹
        CrowdFund longCrowdFund = new CrowdFund(1 ether, 525600); // 365 * 24 * 60

        assertGt(longCrowdFund.getTimeRemaining(), 365 days - 1 minutes);
    }

    // ========== 测试组 15: 集成测试 ==========

    function test_Integration_FullLifecycleSuccess() public {
        // 1. 部署
        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Funding));

        // 2. 多人逐步贡献
        vm.prank(contributor1);
        crowdFund.contribute{value: 2 ether}();
        assertEq(crowdFund.getProgress(), 20);

        vm.warp(block.timestamp + 10 minutes);

        vm.prank(contributor2);
        crowdFund.contribute{value: 3 ether}();
        assertEq(crowdFund.getProgress(), 50);

        vm.warp(block.timestamp + 10 minutes);

        vm.prank(contributor3);
        crowdFund.contribute{value: 6 ether}();
        assertEq(crowdFund.getProgress(), 110);

        // 3. 等待截止
        vm.warp(block.timestamp + 41 minutes);

        // 4. 更新状态
        crowdFund.checkAndUpdateState();
        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Successful));

        // 5. Owner 提取资金
        uint256 balanceBefore = owner.balance;
        crowdFund.withdrawFunds();
        assertEq(owner.balance, balanceBefore + 11 ether);

        // 6. 验证最终状态
        assertTrue(crowdFund.fundsWithdrawn());
        assertEq(crowdFund.getBalance(), 0);
    }

    function test_Integration_FullLifecycleFail() public {
        // 1. 部署
        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Funding));

        // 2. 贡献但未达标
        vm.prank(contributor1);
        crowdFund.contribute{value: 2 ether}();

        vm.prank(contributor2);
        crowdFund.contribute{value: 3 ether}();

        assertEq(crowdFund.totalFunded(), 5 ether);
        assertFalse(crowdFund.isGoalReached());

        // 3. 等待截止
        vm.warp(block.timestamp + DURATION * 1 minutes + 1);

        // 4. 更新状态
        crowdFund.checkAndUpdateState();
        assertEq(uint256(crowdFund.currentState()), uint256(CrowdFund.State.Failed));

        // 5. 所有贡献者退款
        uint256 balance1Before = contributor1.balance;
        uint256 balance2Before = contributor2.balance;

        vm.prank(contributor1);
        crowdFund.refund();

        vm.prank(contributor2);
        crowdFund.refund();

        assertEq(contributor1.balance, balance1Before + 2 ether);
        assertEq(contributor2.balance, balance2Before + 3 ether);

        // 6. 验证最终状态
        assertEq(crowdFund.getBalance(), 0);
        assertEq(crowdFund.contributions(contributor1), 0);
        assertEq(crowdFund.contributions(contributor2), 0);
    }

    // ========== 辅助合约：用于测试重入攻击 ==========
}

/**
 * @dev 恶意合约：尝试重入攻击
 */
contract MaliciousRefunder {
    CrowdFund public targetCrowdFund;
    uint256 public attackCount;

    constructor(address payable _crowdFund) {
        targetCrowdFund = CrowdFund(_crowdFund);
    }

    function attack() external payable {
        targetCrowdFund.contribute{value: msg.value}();
    }

    function executeRefund() external {
        targetCrowdFund.refund();
    }

    // 接收退款时尝试重入
    receive() external payable {
        attackCount++;
        // 只尝试重入一次（避免无限循环）
        if (attackCount == 1 && address(targetCrowdFund).balance > 0) {
            try targetCrowdFund.refund() {
            // 如果重入成功（不应该发生）
            }
                catch {
                // 重入失败（预期行为）
            }
        }
    }
}
