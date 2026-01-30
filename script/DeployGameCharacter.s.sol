// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GameCharacter.sol";

contract DeployGameCharacter is Script {
    function run() external {
        // uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        vm.startBroadcast();

        GameCharacter nft = new GameCharacter();

        console.log("====================================");
        console.log("GameCharacter deployed to:", address(nft));
        console.log("====================================");
        console.log("");
        console.log("Verify on Etherscan:");
        console.log("forge verify-contract", address(nft), "src/GameCharacter.sol:GameCharacter --chain sepolia");
        console.log("");
        console.log("View on OpenSea:");
        console.log("https://testnets.opensea.io/assets/sepolia/", address(nft), "/1");

        // Mint 3 test characters
        console.log("\nMinting 3 test characters...");
        nft.mint(msg.sender);
        nft.mint(msg.sender);
        nft.mint(msg.sender);

        console.log("Minted 3 characters to:", msg.sender);

        vm.stopBroadcast();
    }
}
