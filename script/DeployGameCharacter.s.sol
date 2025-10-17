// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GameCharacter.sol";

contract DeployGameCharacter is Script {
    function run() external {
        // Get the private key from environment or use Anvil's default
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast(deployerPrivateKey);

        // Deploy the contract
        GameCharacter nft = new GameCharacter();

        console.log("GameCharacter deployed to:", address(nft));

        // Mint a test NFT
        nft.mint(msg.sender);
        console.log("Minted NFT #1 to:", msg.sender);

        vm.stopBroadcast();
    }
}
