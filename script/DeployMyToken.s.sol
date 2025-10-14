// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Import the necessary Foundry library and our token contract.
import "forge-std/Script.sol";
import "../src/MyToken.sol"; // Assumes MyToken.sol is in the 'src' folder

// The deployment script contract inherits from Foundry's 'Script' contract.
contract DeployMyToken is Script {

    // The main function that will be executed when we run the script.
    function run() external returns (address) {
        // This is a "cheatcode" from Foundry. It tells the virtual machine
        // to start recording all the transactions we're about to make,
        // so they can be broadcasted to the blockchain.
        vm.startBroadcast();

        // Define the initial supply for our token.
        // We want 1,000 tokens. Since ERC20 tokens typically have 18 decimals,
        // we multiply by 10**18 to represent this correctly.
        uint256 initialSupply = 1000 * 10**18;

        // Deploy a new instance of the MyToken contract, passing the initial supply
        // to its constructor.
        MyToken token = new MyToken(initialSupply);

        // Another Foundry cheatcode. This stops recording and sends the
        // recorded transactions (in our case, just the contract creation) to the network.
        vm.stopBroadcast();
        
        // This is helpful for our records, it will print the new contract address in the logs
        console.log("MyToken contract deployed to:", address(token));

        // Return the address of the newly deployed contract.
        return address(token);
    }
}
