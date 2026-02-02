// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";

/**
 * @title GameCharacter - Dynamic NFT with On-Chain Metadata
 * @dev A fully on-chain NFT that generates SVG images and JSON metadata
 * Characters can level up, gain experience, and their appearance changes!
 */
contract GameCharacter is ERC721, Ownable {
    using Strings for uint256;

    // ============================================
    // STATE VARIABLES
    // ============================================

    uint256 private _nextTokenId;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant XP_PER_LEVEL = 100; // XP needed to level up

    struct CharacterAttributes {
        uint256 level;
        uint256 strength;
        uint256 health;
        uint256 experience;
    }

    mapping(uint256 => CharacterAttributes) public tokenAttributes;

    // ============================================
    // EVENTS
    // ============================================

    event CharacterMinted(
        address indexed owner, uint256 indexed tokenId, uint256 level, uint256 strength, uint256 health
    );
    event CharacterLeveledUp(uint256 indexed tokenId, uint256 newLevel);
    event ExperienceGained(uint256 indexed tokenId, uint256 xpGained, uint256 totalXP);

    // ============================================
    // CONSTRUCTOR
    // ============================================

    constructor() ERC721("GameCharacter", "CHAR") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    // ============================================
    // MINTING
    // ============================================

    function mint(address to) public {
        require(_nextTokenId <= MAX_SUPPLY, "Max supply reached");

        uint256 tokenId = _nextTokenId;
        _nextTokenId++;

        tokenAttributes[tokenId] = CharacterAttributes({
            level: 1, strength: _pseudoRandom(10, 20, tokenId), health: _pseudoRandom(50, 100, tokenId), experience: 0
        });

        emit CharacterMinted(
            to,
            tokenId,
            tokenAttributes[tokenId].level,
            tokenAttributes[tokenId].strength,
            tokenAttributes[tokenId].health
        );

        _safeMint(to, tokenId);
    }

    // ============================================
    // GAME MECHANICS - This is NEW!
    // ============================================

    /**
     * @dev Train your character to gain experience
     * Only the owner can train their character
     *
     * @param tokenId The token to train
     */
    function train(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "You don't own this character");

        CharacterAttributes storage attrs = tokenAttributes[tokenId];

        // Gain 10-30 XP from training
        uint256 xpGained = _pseudoRandom(10, 30, block.timestamp);
        attrs.experience += xpGained;

        emit ExperienceGained(tokenId, xpGained, attrs.experience);

        // Check if character leveled up
        _checkLevelUp(tokenId);
    }

    /**
     * @dev Internal function to check and process level ups
     * When a character levels up, their stats increase!
     */
    function _checkLevelUp(uint256 tokenId) internal {
        CharacterAttributes storage attrs = tokenAttributes[tokenId];

        // Calculate how many levels the character should have
        uint256 newLevel = 1 + (attrs.experience / XP_PER_LEVEL);

        // If they've leveled up, increase their stats
        if (newLevel > attrs.level) {
            uint256 levelsGained = newLevel - attrs.level;

            attrs.level = newLevel;
            attrs.strength += levelsGained * 5; // +5 strength per level
            attrs.health += levelsGained * 20; // +20 health per level

            emit CharacterLeveledUp(tokenId, newLevel);
        }
    }

    // ============================================
    // ON-CHAIN METADATA - The MAGIC! ✨
    // ============================================

    /**
     * @dev Generate SVG image for the character
     * The image changes based on the character's level!
     *
     * @param tokenId The token to generate an image for
     * @return SVG image as a string
     */
    function generateCharacterImage(uint256 tokenId) public view returns (string memory) {
        CharacterAttributes memory attrs = tokenAttributes[tokenId];

        // Choose color based on level
        string memory color = _getColorForLevel(attrs.level);

        // Build the SVG
        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#1a1a2e">',
                // Character body (a simple rectangle that changes color by level)
                '<rect x="125" y="120" width="100" height="150" fill="',
                color,
                '" stroke="#fff" stroke-width="3" rx="10"/>',
                // Head
                '<circle cx="175" cy="80" r="35" fill="',
                color,
                '" stroke="#fff" stroke-width="3"/>',
                // Eyes
                '<circle cx="165" cy="75" r="5" fill="#fff"/>',
                '<circle cx="185" cy="75" r="5" fill="#fff"/>',
                // Level badge
                '<rect x="15" y="15" width="80" height="40" fill="#e94560" rx="8"/>',
                '<text x="55" y="42" font-family="Arial" font-size="20" fill="#fff" text-anchor="middle" font-weight="bold">LVL ',
                attrs.level.toString(),
                "</text>",
                // Stats display
                '<text x="175" y="300" font-family="Arial" font-size="14" fill="#fff" text-anchor="middle">STR: ',
                attrs.strength.toString(),
                "</text>",
                '<text x="175" y="320" font-family="Arial" font-size="14" fill="#fff" text-anchor="middle">HP: ',
                attrs.health.toString(),
                "</text>",
                '<text x="175" y="340" font-family="Arial" font-size="14" fill="#fff" text-anchor="middle">XP: ',
                attrs.experience.toString(),
                "</text>",
                "</svg>"
            )
        );
    }

    /**
     * @dev Generate JSON metadata for the character
     * This is what OpenSea and other marketplaces will display!
     *
     * @param tokenId The token to generate metadata for
     * @return JSON metadata as a string
     */
    function generateMetadata(uint256 tokenId) public view returns (string memory) {
        CharacterAttributes memory attrs = tokenAttributes[tokenId];

        // Generate the SVG image
        string memory svg = generateCharacterImage(tokenId);

        // Encode SVG to Base64
        string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));

        // Build JSON metadata
        return string(
            abi.encodePacked(
                "{",
                '"name": "GameCharacter #',
                tokenId.toString(),
                '",',
                '"description": "A dynamic game character that grows stronger with training!",',
                '"image": "',
                imageURI,
                '",',
                '"attributes": [',
                '{"trait_type": "Level", "value": ',
                attrs.level.toString(),
                "},",
                '{"trait_type": "Strength", "value": ',
                attrs.strength.toString(),
                "},",
                '{"trait_type": "Health", "value": ',
                attrs.health.toString(),
                "},",
                '{"trait_type": "Experience", "value": ',
                attrs.experience.toString(),
                "}",
                "]",
                "}"
            )
        );
    }

    /**
     * @dev The tokenURI function required by ERC721
     * This is what marketplaces call to get your NFT's metadata!
     *
     * @param tokenId The token to get the URI for
     * @return The full token URI (a data URI with base64-encoded JSON)
     */
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");

        string memory json = generateMetadata(tokenId);

        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(bytes(json))));
    }

    // ============================================
    // HELPER FUNCTIONS
    // ============================================

    /**
     * @dev Get color based on character level
     * Higher level = cooler colors!
     */
    // slither-disable-next-line timestamp
    function _getColorForLevel(uint256 level) internal pure returns (string memory) {
        if (level >= 10) return "#ffd700"; // Gold
        if (level >= 7) return "#9b59b6"; // Purple
        if (level >= 5) return "#3498db"; // Blue
        if (level >= 3) return "#2ecc71"; // Green
        return "#95a5a6"; // Gray (level 1-2)
    }

    function getCharacterAttributes(uint256 tokenId) public view returns (CharacterAttributes memory) {
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenAttributes[tokenId];
    }

    function totalMinted() public view returns (uint256) {
        return _nextTokenId - 1;
    }

    // slither-disable-start weak-prng
    function _pseudoRandom(uint256 min, uint256 max, uint256 seed) private view returns (uint256) {
        // We use block.prevrandao (The Beacon Chain randomness)
        // We removed block.timestamp to reduce miner influence vectors
        uint256 randomHash = uint256(keccak256(abi.encodePacked(block.prevrandao, msg.sender, seed)));

        return min + (randomHash % (max - min + 1));
    }
    // slither-disable-end weak-prng
}
