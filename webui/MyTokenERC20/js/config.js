// Network configurations
const NETWORKS = {
    sepolia: {
        chainId: '0xaa36a7', // 11155111
        chainName: 'Sepolia Testnet',
        rpcUrls: ['https://rpc.sepolia.org'], // Using a public RPC
        blockExplorerUrls: ['https://sepolia.etherscan.io'],
        nativeCurrency: { name: 'Sepolia ETH', symbol: 'ETH', decimals: 18 }
    },
    localhost: {
        chainId: '0x7a69', // 31337
        chainName: 'Local Anvil',
        rpcUrls: ['http://127.0.0.1:8545'],
        nativeCurrency: { name: 'ETH', symbol: 'ETH', decimals: 18 }
    },
    mainnet: {
        chainId: '0x1',
        chainName: 'Ethereum Mainnet',
        rpcUrls: ['https://mainnet.infura.io/v3/YOUR_INFURA_KEY'],
        blockExplorerUrls: ['https://etherscan.io'],
        nativeCurrency: { name: 'Ether', symbol: 'ETH', decimals: 18 }
    }
};

// Contract ABI - Your MyToken ERC20 Contract
// Make sure this matches your deployed contract's functions exactly.
const CONTRACT_ABI = [
    "function name() view returns (string)",
    "function symbol() view returns (string)",
    "function decimals() view returns (uint8)",
    "function totalSupply() view returns (uint256)",
    "function balanceOf(address) view returns (uint256)",
    "function allowance(address owner, address spender) view returns (uint256)",
    "function transfer(address to, uint256 value) returns (bool)",
    "function approve(address spender, uint256 value) returns (bool)",
    "function transferFrom(address from, address to, uint256 value) returns (bool)",
    "function increaseAllowance(address spender, uint256 addedValue) returns (bool)",
    "function decreaseAllowance(address spender, uint256 subtractedValue) returns (bool)",
    // NEW -- Added burn function
    "function burn(uint256 amount)",
    // Events
    "event Transfer(address indexed from, address indexed to, uint256 value)",
    "event Approval(address indexed owner, address indexed spender, uint256 value)"
];

// Default contract addresses for each network
const DEFAULT_CONTRACT_ADDRESSES = {
    sepolia: '0x90EC07444b1A6B0A055561566418e44b1b6Ce889', // <-- IMPORTANT: Add your deployed Sepolia address here
    localhost: 'YOUR_LOCALHOST_DEPLOYED_ADDRESS',
    mainnet: ''
};
