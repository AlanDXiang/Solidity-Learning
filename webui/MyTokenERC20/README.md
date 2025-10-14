# 🪙 AlanDXiang Coin (ADX) - ERC20 Token Interface

This is a clean, modern web-based user interface for interacting with any standard ERC20 token smart contract. It is built with vanilla JavaScript and Ethers.js to provide a lightweight and easy-to-understand example of a decentralized application (DApp) frontend.

This interface allows users to connect their MetaMask wallet, view token information, and perform all standard ERC20 actions in a user-friendly way.


*(Recommendation: Take a screenshot of your running application and replace the link above to showcase your project!)*

---

## ✨ Features

-   **Wallet Connection**: Securely connect and disconnect with MetaMask or any EIP-1193 compatible wallet.
-   **Network Switching**: Seamlessly switch between pre-configured networks (e.g., Sepolia, Localhost/Anvil, Mainnet).
-   **Dynamic Contract Loading**: Load any ERC20 contract by pasting its address.
-   **Token Information Display**: View the token's name, symbol, decimals, and total supply.
-   **Balance Checker**: View your personal token balance for the connected account.
-   **Core ERC20 Actions**:
    -   **Transfer**: Send tokens to any address.
    -   **Approve**: Grant another address (a "spender") the right to transfer a certain amount of your tokens.
    -   **Allowance Checker**: Check how many tokens a spender is currently approved to transfer from your account.
    -   **Transfer From**: Execute a delegated transfer on behalf of another user who has approved you.
    -   **Burn**: Irreversibly destroy a specified amount of your own tokens.
-   **Real-time UI Feedback**: Get instant status messages for pending, successful, and failed transactions.
-   **Transaction History**: View a list of your recent transactions with direct links to Etherscan for easy verification.

---

## 🛠️ Tech Stack

-   **Frontend**: `HTML5`, `CSS3`, `Vanilla JavaScript (ES6+)`
-   **Blockchain Interaction**: `Ethers.js (v5)`
-   **Wallet Integration**: MetaMask
-   **Smart Contract Framework (Project Root)**: [Foundry](https://getfoundry.sh/)

---

## 🚀 Getting Started

Follow these instructions to get a copy of the project up and running on your local machine.

### Prerequisites

-   A modern web browser (Chrome, Firefox, Brave).
-   The [MetaMask](https://metamask.io/) browser extension installed and configured.
-   A code editor like [VS Code](https://code.visualstudio.com/).
-   (Optional) For local testing, you need [Foundry](https://getfoundry.sh/) installed to run a local Anvil node.

### Installation & Setup

1.  **Clone the Repository**
    If you haven't already, clone the entire project to your local machine.

2.  **Navigate to the UI Directory**
    Open a terminal and navigate to this specific web UI folder:
    ```bash
    cd path/to/your/project/webui/MyTokenERC20
