// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/GameCharacter.sol";

contract ViewNFT is Script {
    function run() external view {
        // Replace with your deployed contract address
        GameCharacter nft = GameCharacter(0x5FbDB2315678afecb367f032d93F642f64180aa3);

        // Get token URI
        string memory uri = nft.tokenURI(1);
        console.log("Token URI:");
        console.log(uri);

        // Get raw SVG
        string memory svg = nft.generateCharacterImage(1);
        console.log("\nSVG Image:");
        console.log(svg);

        // Get raw JSON
        string memory json = nft.generateMetadata(1);
        console.log("\nJSON Metadata:");
        console.log(json);
    }
}
