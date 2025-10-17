// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GameCharacter.sol";

contract TrainCharacter is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        GameCharacter nft = GameCharacter(0x5FbDB2315678afecb367f032d93F642f64180aa3); // Your address
        
        vm.startBroadcast(deployerPrivateKey);
        
        console.log("=== BEFORE TRAINING ===");
        GameCharacter.CharacterAttributes memory before = nft.getCharacterAttributes(1);
        console.log("Level:", before.level);
        console.log("XP:", before.experience);
        console.log("Strength:", before.strength);
        
        // Train 15 times to level up!
	console.log("Training 15 times...");
        for (uint i = 0; i < 15; i++) {
            nft.train(1);
        }
        
        console.log("\n=== AFTER TRAINING ===");
        GameCharacter.CharacterAttributes memory after = nft.getCharacterAttributes(1);
        console.log("Level:", after.level);
        console.log("XP:", after.experience);
        console.log("Strength:", after.strength);
        console.log("\n✨ Character leveled up!");
        
        vm.stopBroadcast();
    }
}
