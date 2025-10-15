// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/GameCharacter.sol";

contract GameCharacterTest is Test {
    GameCharacter public nft;
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    function setUp() public {
        nft = new GameCharacter();
    }
    
    function testMint() public {
        // Mint NFT to user1
        nft.mint(user1);
        
        // Check that user1 owns token #1
        assertEq(nft.ownerOf(1), user1);
        
        // Check total minted
        assertEq(nft.totalMinted(), 1);
    }
    
    function testCharacterAttributes() public {
        // Mint NFT
        nft.mint(user1);
        
        // Get attributes
        GameCharacter.CharacterAttributes memory attrs = nft.getCharacterAttributes(1);
        
        // Verify initial state
        assertEq(attrs.level, 1);
        assertTrue(attrs.strength >= 10 && attrs.strength <= 20);
        assertTrue(attrs.health >= 50 && attrs.health <= 100);
        assertEq(attrs.experience, 0);
    }
    
    function testMultipleMints() public {
        // Mint to different users
        nft.mint(user1);
        nft.mint(user2);
        nft.mint(user1);
        
        // Verify ownership
        assertEq(nft.ownerOf(1), user1);
        assertEq(nft.ownerOf(2), user2);
        assertEq(nft.ownerOf(3), user1);
        
        // User1 should have 2 NFTs
        assertEq(nft.balanceOf(user1), 2);
        assertEq(nft.balanceOf(user2), 1);
    }
    
    function testCannotMintBeyondMaxSupply() public {
        // Try to mint token #1001 (should fail)
        vm.expectRevert("Max supply reached");
        for (uint256 i = 0; i <= 1000; i++) {
            nft.mint(user1);
        }
    }
}
