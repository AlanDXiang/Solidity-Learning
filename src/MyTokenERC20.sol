// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title MyToken - A Complete ERC20 Implementation
 * @notice Educational ERC20 token with all standard functions
 * @dev Implements the ERC20 standard interface
 */
contract MyToken {
    // ===== TOKEN METADATA =====
    string public constant name = "AlanDXiang Coin";
    string public constant symbol = "ADX";
    uint8 public constant decimals = 18;

    // ===== CORE STATE VARIABLES =====
    uint256 public totalSupply;

    // Mapping: address => their token balance
    mapping(address => uint256) public balanceOf;

    // Nested Mapping: owner => (spender => amount allowed to spend)
    // Example: You allow Uniswap to spend 100 of your tokens
    mapping(address => mapping(address => uint256)) public allowance;

    // ===== EVENTS =====
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(
        address indexed owner,
        address indexed spender,
        uint256 value
    );

    // ===== CONSTRUCTOR =====
    constructor(uint256 _initialSupply) {
        totalSupply = _initialSupply * 10 ** decimals;
        balanceOf[msg.sender] = totalSupply;
        emit Transfer(address(0), msg.sender, totalSupply);
    }

    // ===== CORE FUNCTIONS =====

    /**
     * @notice Transfer tokens from your account to another
     * @param _to Recipient address
     * @param _value Amount of tokens to send (in smallest unit)
     * @return success True if transfer succeeded
     */
    function transfer(
        address _to,
        uint256 _value
    ) public returns (bool success) {
        // Security Check 1: Can't send to zero address (burning tokens)
        require(_to != address(0), "Cannot transfer to zero address");

        // Security Check 2: You must have enough tokens
        require(balanceOf[msg.sender] >= _value, "Insufficient balance");

        // Perform the transfer
        balanceOf[msg.sender] -= _value; // Subtract from sender
        balanceOf[_to] += _value; // Add to recipient

        // Emit event for blockchain explorers
        emit Transfer(msg.sender, _to, _value);

        return true;
    }

    /**
     * @notice Approve another address to spend your tokens
     * @dev This is how DEXs work - you approve them to move your tokens
     * @param _spender Address authorized to spend
     * @param _value Maximum amount they can spend
     * @return success True if approval succeeded
     */
    function approve(
        address _spender,
        uint256 _value
    ) public returns (bool success) {
        require(_spender != address(0), "Cannot approve zero address");

        // Set the allowance
        allowance[msg.sender][_spender] = _value;

        // Emit approval event
        emit Approval(msg.sender, _spender, _value);

        return true;
    }

    /**
     * @notice Transfer tokens on behalf of another address
     * @dev Used by DEXs and smart contracts after approval
     * @param _from Address to transfer from (must have approved you)
     * @param _to Recipient address
     * @param _value Amount to transfer
     * @return success True if transfer succeeded
     */
    function transferFrom(
        address _from,
        address _to,
        uint256 _value
    ) public returns (bool success) {
        require(_to != address(0), "Cannot transfer to zero address");
        require(_value <= balanceOf[_from], "Insufficient balance");
        require(_value <= allowance[_from][msg.sender], "Allowance exceeded");

        // Update balances
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;

        // Reduce the allowance
        allowance[_from][msg.sender] -= _value;

        // Emit transfer event
        emit Transfer(_from, _to, _value);

        return true;
    }

    // ===== OPTIONAL UTILITY FUNCTIONS =====

    /**
     * @notice Increase the allowance for a spender
     * @dev Safer than approve() for incrementing allowance
     */
    function increaseAllowance(
        address _spender,
        uint256 _addedValue
    ) public returns (bool) {
        require(_spender != address(0), "Cannot approve zero address");

        allowance[msg.sender][_spender] += _addedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    /**
     * @notice Decrease the allowance for a spender
     */
    function decreaseAllowance(
        address _spender,
        uint256 _subtractedValue
    ) public returns (bool) {
        require(_spender != address(0), "Cannot approve zero address");

        uint256 currentAllowance = allowance[msg.sender][_spender];
        require(
            currentAllowance >= _subtractedValue,
            "Decreased allowance below zero"
        );

        allowance[msg.sender][_spender] = currentAllowance - _subtractedValue;
        emit Approval(msg.sender, _spender, allowance[msg.sender][_spender]);

        return true;
    }

    /**
     * @notice Burn (destroy) your own tokens
     * @dev Reduces total supply permanently
     */
    function burn(uint256 _value) public returns (bool success) {
        require(
            balanceOf[msg.sender] >= _value,
            "Insufficient balance to burn"
        );

        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;

        emit Transfer(msg.sender, address(0), _value);
        return true;
    }
}
