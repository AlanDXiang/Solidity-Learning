// Handles all direct interaction with the smart contract
class TokenContract {
    constructor() {
        this.provider = null;
        this.signer = null;
        this.contract = null;
        this.contractAddress = null;
        this.decimals = 18; // Default, will be updated from contract
    }

    async init(provider, signer) {
        this.provider = provider;
        this.signer = signer;
    }

    loadContract(address) {
        this.contractAddress = address;
        if (!this.provider || !this.signer) {
            throw new Error('Provider and signer not initialized.');
        }
        this.contract = new ethers.Contract(address, CONTRACT_ABI, this.signer);
    }

    async getTokenInfo() {
        if (!this.contract) throw new Error('Contract not loaded.');

        const [name, symbol, decimals, totalSupply] = await Promise.all([
            this.contract.name(),
            this.contract.symbol(),
            this.contract.decimals(),
            this.contract.totalSupply()
        ]);

        this.decimals = decimals;

        // formatUnits converts from the smallest unit (like wei) to the main unit (like Ether)
        const formattedTotalSupply = ethers.utils.formatUnits(totalSupply, this.decimals);

        return { name, symbol, decimals, totalSupply: formattedTotalSupply };
    }

    async getBalance(userAddress) {
        if (!this.contract) throw new Error('Contract not loaded.');
        const balance = await this.contract.balanceOf(userAddress);
        return ethers.utils.formatUnits(balance, this.decimals);
    }

    // NEW - Get allowance for a spender
    async getAllowance(owner, spender) {
        if (!this.contract) throw new Error('Contract not loaded.');
        const allowance = await this.contract.allowance(owner, spender);
        return ethers.utils.formatUnits(allowance, this.decimals);
    }

    // --- Transactions ---

    async transfer(to, amount) {
        // parseUnits converts from the main unit (like Ether) to the smallest unit (like wei)
        const parsedAmount = ethers.utils.parseUnits(amount, this.decimals);
        const tx = await this.contract.transfer(to, parsedAmount);
        return tx.wait(); // Wait for transaction to be mined
    }

    async approve(spender, amount) {
        const parsedAmount = ethers.utils.parseUnits(amount, this.decimals);
        const tx = await this.contract.approve(spender, parsedAmount);
        return tx.wait();
    }

    async transferFrom(from, to, amount) {
        const parsedAmount = ethers.utils.parseUnits(amount, this.decimals);
        const tx = await this.contract.transferFrom(from, to, parsedAmount);
        return tx.wait();
    }

    // NEW -- Burn function
    async burn(amount) {
        const parsedAmount = ethers.utils.parseUnits(amount, this.decimals);
        const tx = await this.contract.burn(parsedAmount);
        return tx.wait();
    }

    setupEventListeners(handler) {
        if (!this.contract) return;
        this.contract.on('Transfer', (from, to, value, event) => {
            handler('Transfer', { from, to, value, event });
        });
        this.contract.on('Approval', (owner, spender, value, event) => {
            handler('Approval', { owner, spender, value, event });
        });
    }
}
