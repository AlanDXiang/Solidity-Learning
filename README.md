# My Solidity & Foundry Learning Journey

Welcome to my Solidity learning repository! This project serves as my personal playground and journal as I dive into the world of blockchain, smart contracts, and Web3 development using the Foundry framework.

## 📖 About This Project

The purpose of this repository is to document my progress, starting from fundamental "Hello World" style contracts and moving towards more complex decentralized applications (DApps). Each contract is a step in my learning path, complete with corresponding tests to ensure correctness and enforce a Test-Driven Development (TDD) mindset.

## 🛠️ Tech Stack & Tools

*   **Solidity:** The primary language for writing smart contracts on Ethereum and other EVM-compatible blockchains.
*   **Foundry:** A blazing fast, portable, and modular toolkit for Ethereum application development written in Rust.
    *   **Forge:** Used for compiling, testing, and deploying smart contracts.
    *   **Cast:** My command-line tool for interacting with smart contracts, sending transactions, and getting chain data.

## 📁 Project Structure

This project follows the standard Foundry directory structure:

```
.
├── lib/          # Git submodules for external libraries (e.g., forge-std)
├── script/       # Deployment scripts
├── src/          # Source code for the smart contracts
├── test/         # Test suites for the smart contracts
├── foundry.toml  # Foundry configuration file
└── README.md     # You are here!
```

## 🚀 Contracts Included

Here's a summary of the smart contracts I have built so far:

### `src/Counter.sol`
A simple counter contract that serves as a "Hello World" to the basics of Solidity. It demonstrates:
*   State variables (`uint public number`)
*   Basic functions (`setNumber`, `increment`)
*   Testing with `Counter.t.sol`

### `src/CrowdFund.sol`
A more complex contract simulating a crowdfunding platform. This project explores concepts like:
*   Receiving ETH (`receive() external payable`)
*   Managing contributions with mappings (`mapping(address => uint)`)
*   Enforcing rules and deadlines with `require()`
*   Owner-only privileges

### `src/Voting/Voting.sol`
A decentralized voting system. This contract is a deeper dive into:
*   Structs to represent complex data (e.g., Proposals)
*   Managing permissions and voter eligibility
*   Tallying votes and determining a winner
*   **Learning Notes:** My detailed thoughts and learning summary for this contract can be found in `src/Voting/Voting_Learning_Summary.md`.

## ⚙️ Getting Started

To get this project running locally, follow these steps:

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/AlanDXiang/Solidity-Learning.git
    cd SOLIDITY_LEARNING
    ```

2.  **Install Foundry:**
    If you don't have Foundry installed, follow the official instructions:
    ```bash
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
    ```

3.  **Install dependencies:**
    This project uses `forge-std` as a dependency. Install it using:
    ```bash
    forge install
    ```

4.  **Compile the contracts:**
    ```bash
    forge build
    ```

5.  **Run the tests:**
    ```bash
    forge test
    ```

## 🎯 Future Goals

My next steps in this learning journey include:
*   [ ] Building an ERC20 Token
*   [ ] Creating an ERC721 (NFT) contract
*   [ ] Exploring gas optimization techniques
*   [ ] Learning about common security vulnerabilities like re-entrancy.

Thanks for checking out my project!

