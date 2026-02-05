// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {
    IERC20
} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

contract Staking {
    IERC20 public immutable stakingToken;
    IERC20 public immutable rewardsToken;

    // --- State Variables ---
    uint256 public rewardRate = 100; // 100 tokens per second (example)
    uint256 public lastUpdateTime;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    constructor(address _stakingToken, address _rewardsToken) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
    }

    // Helper to see total staked
    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // Helper to see user balance
    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }
}
