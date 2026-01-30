// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GameCharacter.sol";

// to run this script:
// forge script script/InteractSepolia.s.sol:InteractSepolia --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast -vvvv

// interact with command to train character on Sepolia.
// Make sure your environment variables are set first!
// cast send 0xD8aeeA4af402349a31399b05B69F94F91149e946 "mint(address)" $RECIPIENT_ADDRESS --rpc-url $SEPOLIA_RPC_URL --private-key $MINTER_PRIVATE_KEY
// cast send 0xD8aeeA4af402349a31399b05B69F94F91149e946 "train(uint256)" 4 --rpc-url $SEPOLIA_RPC_URL --private-key $MINTER_PRIVATE_KEY

contract InteractSepolia is Script {
    function run() external {
        // 👇 REPLACE WITH YOUR DEPLOYED SEPOLIA ADDRESS
        address nftAddress = 0xD8aeeA4af402349a31399b05B69F94F91149e946;

        GameCharacter nft = GameCharacter(nftAddress);

        vm.startBroadcast();

        console.log("=== TRAINING CHARACTER #1 ===");

        // Get initial stats
        GameCharacter.CharacterAttributes memory before = nft.getCharacterAttributes(1);
        console.log("Before - Level:", before.level, "XP:", before.experience);

        // Train 10 times
        for (uint256 i = 0; i < 10; i++) {
            nft.train(1);
            console.log("Training session", i + 1, "completed!");
        }

        // Get new stats
        GameCharacter.CharacterAttributes memory after_train = nft.getCharacterAttributes(1);
        console.log("After - Level:", after_train.level, "XP:", after_train.experience);

        console.log("Character leveled up on Sepolia!");
        console.log("View on OpenSea:");
        console.log("https://testnets.opensea.io/assets/sepolia/", nftAddress, "/1");

        vm.stopBroadcast();
    }
}
