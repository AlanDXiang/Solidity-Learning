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
        GameCharacter.CharacterAttributes memory attrs = nft
            .getCharacterAttributes(1);

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
        // Mint 1001 tokens, catch when it fails
        uint256 successfulMints = 0;

        for (uint256 i = 0; i < 1001; i++) {
            try nft.mint(user1) {
                successfulMints++;
            } catch {
                // Expected to fail at 1001
                break;
            }
        }

        // Should have successfully minted exactly 1000
        assertEq(successfulMints, 1000);
        assertEq(nft.totalMinted(), 1000);
    }

    // Add these test functions to your existing GameCharacterTest contract

    function testTraining() public {
        // Mint character
        nft.mint(user1);

        // Get initial attributes
        GameCharacter.CharacterAttributes memory attrsBefore = nft
            .getCharacterAttributes(1);
        uint256 initialXP = attrsBefore.experience;

        // Train as user1
        vm.prank(user1);
        nft.train(1);

        // Check XP increased
        GameCharacter.CharacterAttributes memory attrsAfter = nft
            .getCharacterAttributes(1);
        assertTrue(attrsAfter.experience > initialXP, "XP should increase");
    }

    function testLevelUp() public {
        nft.mint(user1);

        // Train 10 times to gain enough XP
        vm.startPrank(user1);
        for (uint i = 0; i < 10; i++) {
            nft.train(1);
        }
        vm.stopPrank();

        // Character should have leveled up
        GameCharacter.CharacterAttributes memory attrs = nft
            .getCharacterAttributes(1);
        assertTrue(attrs.level > 1, "Should have leveled up");
        assertTrue(attrs.strength > 20, "Strength should have increased");
    }

    function testOnlyOwnerCanTrain() public {
        nft.mint(user1);

        // User2 tries to train user1's character
        vm.prank(user2);
        vm.expectRevert("You don't own this character");
        nft.train(1);
    }

    function testTokenURI() public {
        nft.mint(user1);

        string memory uri = nft.tokenURI(1);

        // Should start with data URI scheme
        assertTrue(bytes(uri).length > 0, "URI should not be empty");

        // Should contain "data:application/json;base64,"
        // (We can't easily decode it in Solidity, but we can check it exists)
    }

    function testGenerateMetadata() public {
        nft.mint(user1);

        string memory metadata = nft.generateMetadata(1);

        // Should contain expected JSON fields
        assertTrue(bytes(metadata).length > 0, "Metadata should not be empty");
    }
}
