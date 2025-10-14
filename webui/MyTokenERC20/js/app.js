// Main application logic
class TokenDApp {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.userAddress = null;
        this.currentNetwork = 'sepolia'; // Default network
        this.tokenContract = new TokenContract();
        this.transactions = [];

        this.init();
    }

    async init() {
        this.setupEventListeners();
        await this.checkWalletConnection();
    }

    // NEW --- Event Listeners to connect UI to logic
    setupEventListeners() {
        // Connect Wallet Button
        document.getElementById('connectWallet').addEventListener('click', () => this.connectWallet());

        // Network Selector Dropdown
        document.getElementById('network').addEventListener('change', (e) => this.switchNetwork(e.target.value));

        // Load Contract Button
        document.getElementById('loadContract').addEventListener('click', () => {
            const address = document.getElementById('contractAddress').value;
            this.loadContract(address);
        });

        // --- Tab Navigation ---
        const tabs = document.querySelectorAll('.tab-btn');
        const tabContents = document.querySelectorAll('.tab-content');
        tabs.forEach(tab => {
            tab.addEventListener('click', () => {
                // Remove active class from all
                tabs.forEach(t => t.classList.remove('active'));
                tabContents.forEach(c => c.classList.remove('active'));

                // Add active class to the clicked tab and its content
                tab.classList.add('active');
                document.getElementById(tab.dataset.tab).classList.add('active');
            });
        });

        // --- Forms ---

        // Transfer Form
        document.getElementById('transferForm').addEventListener('submit', (e) => {
            e.preventDefault(); // Prevents page reload
            const to = document.getElementById('transferTo').value;
            const amount = document.getElementById('transferAmount').value;
            this.handleTransfer(to, amount);
        });

        // Approve Form
        document.getElementById('approveForm').addEventListener('submit', (e) => {
            e.preventDefault();
            const spender = document.getElementById('approveSpender').value;
            const amount = document.getElementById('approveAmount').value;
            this.handleApprove(spender, amount);
        });

        // Transfer From Form
        document.getElementById('transferFromForm').addEventListener('submit', (e) => {
            e.preventDefault();
            const from = document.getElementById('transferFromAddress').value;
            const to = document.getElementById('transferFromTo').value;
            const amount = document.getElementById('transferFromAmount').value;
            this.handleTransferFrom(from, to, amount);
        });

        // Burn Form (New Handler)
        document.getElementById('burnForm').addEventListener('submit', (e) => {
            e.preventDefault();
            const amount = document.getElementById('burnAmount').value;
            this.handleBurn(amount);
        });

        // Check Allowance Button
        document.getElementById('checkAllowance').addEventListener('click', async () => {
            const spender = document.getElementById('checkSpender').value;
            if (!this.userAddress || !spender) {
                this.showStatus('Please connect wallet and enter a spender address.', 'error');
                return;
            }
            try {
                const allowance = await this.tokenContract.getAllowance(this.userAddress, spender);
                document.getElementById('allowanceResult').textContent = allowance;
            } catch (error) {
                this.showStatus('Could not check allowance: ' + error.message, 'error');
            }
        });
    }

    // ===== WALLET CONNECTION =====
    async checkWalletConnection() {
        if (typeof window.ethereum === 'undefined') {
            this.showStatus('Please install MetaMask to use this dApp', 'error');
            return;
        }

        const accounts = await window.ethereum.request({ method: 'eth_accounts' });
        if (accounts.length > 0) {
            await this.connectWallet();
        }
    }

    async connectWallet() {
        try {
            if (typeof window.ethereum === 'undefined') {
                throw new Error('MetaMask not installed');
            }

            const accounts = await window.ethereum.request({ method: 'eth_requestAccounts' });
            this.userAddress = accounts[0];

            this.provider = new ethers.providers.Web3Provider(window.ethereum);
            this.signer = this.provider.getSigner();

            await this.tokenContract.init(this.provider, this.signer);

            this.updateWalletUI();
            await this.switchNetwork(this.currentNetwork);

            this.setupMetaMaskListeners();
            this.showStatus('Wallet connected successfully!', 'success');

        } catch (error) {
            console.error('Connection error:', error);
            this.showStatus('Failed to connect wallet: ' + error.message, 'error');
        }
    }

    setupMetaMaskListeners() {
        window.ethereum.on('accountsChanged', (accounts) => {
            if (accounts.length === 0) {
                this.disconnectWallet();
            } else {
                this.userAddress = accounts[0];
                this.updateWalletUI();
                this.refreshTokenInfo();
            }
        });

        window.ethereum.on('chainChanged', () => window.location.reload());
    }

    disconnectWallet() {
        this.userAddress = null;
        this.provider = null;
        this.signer = null;
        document.getElementById('walletInfo').classList.add('hidden');
        document.getElementById('connectWallet').classList.remove('hidden');
        document.getElementById('userBalance').textContent = '-';
    }

    updateWalletUI() {
        const walletInfo = document.getElementById('walletInfo');
        const connectBtn = document.getElementById('connectWallet');
        const addressSpan = document.getElementById('walletAddress');

        if (this.userAddress) {
            const shortAddress = `${this.userAddress.slice(0, 6)}...${this.userAddress.slice(-4)}`;
            addressSpan.textContent = shortAddress;
            walletInfo.classList.remove('hidden');
            connectBtn.classList.add('hidden');
        }
    }

    // ===== NETWORK SWITCHING =====
    async switchNetwork(networkKey) {
        try {
            this.currentNetwork = networkKey;
            const network = NETWORKS[networkKey];

            if (!network) {
                throw new Error(`Network '${networkKey}' not configured.`);
            }

            if (window.ethereum.networkVersion !== parseInt(network.chainId, 16).toString()) {
                await window.ethereum.request({
                    method: 'wallet_switchEthereumChain',
                    params: [{ chainId: network.chainId }],
                });
            }

            this.updateNetworkIndicator(networkKey);

            // Load default contract address if available
            const defaultAddress = DEFAULT_CONTRACT_ADDRESSES[networkKey];
            if (defaultAddress) {
                document.getElementById('contractAddress').value = defaultAddress;
                await this.loadContract(defaultAddress);
            } else {
                document.getElementById('contractAddress').value = '';
            }

        } catch (error) {
            console.error('Network switch error:', error);
            this.showStatus('Failed to switch network: ' + error.message, 'error');
        }
    }

    updateNetworkIndicator(networkKey) {
        const indicator = document.getElementById('networkIndicator');
        indicator.className = `network-badge ${networkKey}`;
        indicator.textContent = NETWORKS[networkKey].chainName;
    }

    // ===== CONTRACT INTERACTION =====
    async loadContract(address) {
        try {
            if (!ethers.utils.isAddress(address)) {
                throw new Error('Invalid contract address');
            }

            this.tokenContract.loadContract(address);
            await this.refreshTokenInfo();

            this.tokenContract.setupEventListeners((eventName, data) => {
                this.handleContractEvent(eventName, data);
            });

            this.showStatus('Contract loaded successfully!', 'success');

        } catch (error) {
            console.error('Load contract error:', error);
            this.showStatus('Failed to load contract: ' + error.message, 'error');
        }
    }

    async refreshTokenInfo() {
        try {
            if (!this.tokenContract.contract) { return; }
            const info = await this.tokenContract.getTokenInfo();

            document.getElementById('tokenName').textContent = info.name;
            document.getElementById('tokenSymbol').textContent = info.symbol;
            document.getElementById('tokenDecimals').textContent = info.decimals;
            document.getElementById('totalSupply').textContent = `${info.totalSupply} ${info.symbol}`;

            if (this.userAddress) {
                const balance = await this.tokenContract.getBalance(this.userAddress);
                document.getElementById('userBalance').textContent = `${balance} ${info.symbol}`;
            }

        } catch (error) {
            console.error('Refresh error:', error);
            this.showStatus('Could not refresh token info. Is the contract address correct for this network?', 'error');
        }
    }

    // ===== TRANSACTION HANDLERS =====
    async handleTransfer(to, amount) {
        try {
            this.showStatus('Sending transaction...', 'info');
            const receipt = await this.tokenContract.transfer(to, amount);

            this.addTransaction('Transfer', receipt.transactionHash, 'success');
            await this.refreshTokenInfo();
            this.showStatus('Transfer successful!', 'success');

        } catch (error) {
            console.error('Transfer error:', error);
            this.showStatus('Transfer failed: ' + error.message, 'error');
        }
    }

    async handleApprove(spender, amount) {
        try {
            this.showStatus('Sending approval...', 'info');
            const receipt = await this.tokenContract.approve(spender, amount);

            this.addTransaction('Approval', receipt.transactionHash, 'success');
            this.showStatus('Approval successful!', 'success');

        } catch (error) {
            console.error('Approve error:', error);
            this.showStatus('Approval failed: ' + error.message, 'error');
        }
    }

    async handleTransferFrom(from, to, amount) {
        try {
            this.showStatus('Executing transfer from...', 'info');
            const receipt = await this.tokenContract.transferFrom(from, to, amount);

            this.addTransaction('TransferFrom', receipt.transactionHash, 'success');
            await this.refreshTokenInfo();
            this.showStatus('Transfer From successful!', 'success');

        } catch (error) {
            console.error('TransferFrom error:', error);
            this.showStatus('Transfer From failed: ' + error.message, 'error');
        }
    }

    // NEW -- Burn handler
    async handleBurn(amount) {
        try {
            this.showStatus('Burning tokens...', 'info');
            const receipt = await this.tokenContract.burn(amount);

            this.addTransaction('Burn', receipt.transactionHash, 'success');
            await this.refreshTokenInfo();
            this.showStatus('Burn successful!', 'success');

        } catch (error) {
            console.error('Burn error:', error);
            this.showStatus('Burn failed: ' + error.message, 'error');
        }
    }

    // ===== UI FEEDBACK =====

    // NEW -- Implementation for status messages
    showStatus(message, type) {
        const statusMessage = document.getElementById('statusMessage');
        statusMessage.textContent = message;
        statusMessage.className = `status-message ${type}`; // e.g., 'success', 'error', 'info'

        // Hide message after 5 seconds
        setTimeout(() => {
            statusMessage.className = 'status-message hidden';
        }, 5000);
    }

    // NEW -- Implementation for transaction history
    addTransaction(type, hash) {
        const txHistory = document.getElementById('txHistory');
        const explorerUrl = NETWORKS[this.currentNetwork].blockExplorerUrls[0];

        const txElement = document.createElement('div');
        txElement.className = 'tx-item';
        txElement.innerHTML = `
            <strong>${type}:</strong> 
            <a href="${explorerUrl}/tx/${hash}" target="_blank">${hash.slice(0, 10)}...${hash.slice(-8)}</a>
        `;

        // Add the new transaction to the top of the list
        txHistory.prepend(txElement);

        // Keep the list from getting too long
        while (txHistory.children.length > 10) {
            txHistory.removeChild(txHistory.lastChild);
        }
    }

    handleContractEvent(eventName, data) {
        console.log(`Event: ${eventName}`, data);
        this.showStatus(`Event Received: ${eventName}!`, 'info');
        this.refreshTokenInfo();
    }
}

// Initialize the DApp
window.addEventListener('load', () => {
    new TokenDApp();
});
