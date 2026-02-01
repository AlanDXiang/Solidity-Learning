// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title CrowdFund
 * @dev 一个去中心化的众筹合约
 * @notice 本合约允许创建者发起众筹，参与者贡献资金
 */
contract CrowdFund {
    // ========== 状态变量 ==========

    // 合约创建者（项目发起人）
    address public owner;

    // 众筹目标金额（单位：wei）
    uint256 public goal;

    // 众筹截止时间（Unix时间戳）
    uint256 public deadline;

    // 当前已筹集的总金额
    uint256 public totalFunded;

    // 记录每个地址贡献的金额
    mapping(address => uint256) public contributions;

    // 众筹状态枚举
    enum State {
        Funding,
        Successful,
        Failed
    }

    // 当前状态（默认为 Funding）
    State public currentState;

    // 标记资金是否已被提取
    bool public fundsWithdrawn;

    // ========== 事件 ==========

    // 当有人贡献资金时触发
    event ContributionReceived(
        address indexed contributor,
        uint256 amount,
        uint256 totalFunded
    );

    // 当创建者提取资金时触发
    event FundsWithdrawn(address indexed owner, uint256 amount);

    // 当贡献者申请退款时触发
    event RefundIssued(address indexed contributor, uint256 amount);

    // 当众筹状态改变时触发
    event StateChanged(State newState);

    // ========== 修饰器 ==========

    // 只有合约创建者可以调用
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    // 只有在指定状态下才能调用
    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this operation");
        _;
    }

    // 只有在众筹期间才能调用
    modifier beforeDeadline() {
        require(block.timestamp < deadline, "Crowdfund has ended");
        _;
    }

    // 只有在截止时间后才能调用
    modifier afterDeadline() {
        require(block.timestamp >= deadline, "Crowdfund is still active");
        _;
    }

    // ========== 构造函数 ==========

    /**
     * @dev 初始化众筹合约
     * @param _goal 众筹目标金额（单位：wei）
     * @param _durationInMinutes 众筹持续时间（单位：分钟）
     */
    constructor(uint256 _goal, uint256 _durationInMinutes) {
        require(_goal > 0, "Goal must be greater than 0");
        require(_durationInMinutes > 0, "Duration must be greater than 0");

        owner = msg.sender;
        goal = _goal;
        deadline = block.timestamp + (_durationInMinutes * 1 minutes);
        currentState = State.Funding;
        fundsWithdrawn = false;
        totalFunded = 0;
    }

    // ========== 核心函数 ==========

    /**
     * @dev 参与众筹（贡献资金）
     * @notice 发送ETH到此函数即可参与众筹
     */
    function contribute() public payable beforeDeadline inState(State.Funding) {
        require(msg.value > 0, "Contribution must be greater than 0");

        // 更新贡献记录
        contributions[msg.sender] += msg.value;
        totalFunded += msg.value;

        emit ContributionReceived(msg.sender, msg.value, totalFunded);
    }

    /**
     * @dev 检查并更新众筹状态
     * @notice 任何人都可以调用此函数来更新状态
     */
    function checkAndUpdateState() public afterDeadline {
        // 如果状态不是 Funding，无需更新
        if (currentState != State.Funding) {
            return;
        }

        // 根据筹集金额更新状态
        if (totalFunded >= goal) {
            currentState = State.Successful;
            emit StateChanged(State.Successful);
        } else {
            currentState = State.Failed;
            emit StateChanged(State.Failed);
        }
    }

    /**
     * @dev 创建者提取资金（仅在成功时）
     * @notice 只有合约创建者可以调用
     */
    function withdrawFunds()
        public
        onlyOwner
        afterDeadline
        inState(State.Successful)
    {
        require(!fundsWithdrawn, "Funds already withdrawn");

        fundsWithdrawn = true;
        uint256 amount = address(this).balance;

        emit FundsWithdrawn(owner, amount);

        // 使用 call 转账（推荐的安全方式）
        (bool success, ) = payable(owner).call{value: amount}("");
        require(success, "Transfer failed");
    }

    /**
     * @dev 贡献者申请退款（仅在失败时）
     * @notice 只有参与过众筹的人可以退款
     */
    function refund() public afterDeadline inState(State.Failed) {
        uint256 contributedAmount = contributions[msg.sender];
        require(contributedAmount > 0, "No contribution to refund");

        // 先更新状态，防止重入攻击（Checks-Effects-Interactions 模式）
        contributions[msg.sender] = 0;

        emit RefundIssued(msg.sender, contributedAmount);

        // 转账退款
        (bool success, ) = payable(msg.sender).call{value: contributedAmount}(
            ""
        );
        require(success, "Refund transfer failed");
    }

    // ========== 查询函数 ==========

    /**
     * @dev 获取合约当前余额
     */
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    /**
     * @dev 获取剩余时间（秒）
     */
    function getTimeRemaining() public view returns (uint256) {
        // slither-disable-next-line timestamp
        if (block.timestamp >= deadline) {
            return 0;
        }
        return deadline - block.timestamp;
    }

    /**
     * @dev 获取众筹进度百分比（0-100）
     */
    function getProgress() public view returns (uint256) {
        if (goal == 0) return 0;
        return (totalFunded * 100) / goal;
    }

    /**
     * @dev 检查某个地址的贡献金额
     */
    function getContribution(
        address _contributor
    ) public view returns (uint256) {
        return contributions[_contributor];
    }

    /**
     * @dev 获取众筹是否达标
     */
    function isGoalReached() public view returns (bool) {
        return totalFunded >= goal;
    }

    // ========== 接收函数 ==========

    /**
     * @dev 接收直接发送到合约的ETH
     * @notice 自动调用 contribute() 函数
     */
    receive() external payable {
        contribute();
    }

    /**
     * @dev 回退函数
     */
    fallback() external payable {
        contribute();
    }
}
