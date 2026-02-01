// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract EvolvingGameCharacter is ERC721, Ownable {
    using Strings for uint256;

    uint256 private _nextTokenId;
    uint256 public constant MAX_SUPPLY = 1000;
    uint256 public constant XP_PER_LEVEL = 100;

    struct CharacterAttributes {
        uint256 level;
        uint256 strength;
        uint256 health;
        uint256 experience;
    }

    mapping(uint256 => CharacterAttributes) public tokenAttributes;

    constructor() ERC721("EvolvingBot", "EVO") Ownable(msg.sender) {
        _nextTokenId = 1;
    }

    // --- Core Actions ---

    function mint(address to) public {
        require(_nextTokenId <= MAX_SUPPLY, "Max supply reached");
        uint256 tokenId = _nextTokenId++;

        tokenAttributes[tokenId] = CharacterAttributes({
            level: 1, strength: _pseudoRandom(10, 20, tokenId), health: _pseudoRandom(80, 120, tokenId), experience: 0
        });

        _safeMint(to, tokenId);
    }

    function train(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not owner");
        CharacterAttributes storage attrs = tokenAttributes[tokenId];

        attrs.experience += _pseudoRandom(15, 35, block.timestamp);
        uint256 newLevel = 1 + (attrs.experience / XP_PER_LEVEL);

        if (newLevel > attrs.level) {
            attrs.level = newLevel;
            attrs.strength += 7;
            attrs.health += 25;
        }
    }

    // --- On-Chain SVG Engine ---

    function generateCharacterImage(uint256 tokenId) public view returns (string memory) {
        CharacterAttributes memory attrs = tokenAttributes[tokenId];

        // Dynamic Layering: Crown (Lvl 10+)
        string memory crown = attrs.level >= 10
            ? '<path d="M155 45 L165 55 L175 45 L185 55 L195 45 V65 H155 Z" fill="#FFD700" stroke="#000"/>'
            : "";

        // Dynamic Layering: Visor (Lvl 5+) vs Eyes (Lvl 1-4)
        string memory face = attrs.level >= 5
            ? string(
                abi.encodePacked(
                    '<rect x="150" y="72" width="50" height="12" rx="6" fill="', _getSecondaryColor(attrs.level), '"/>'
                )
            )
            : '<circle cx="165" cy="75" r="5" fill="#FFF"/><circle cx="185" cy="75" r="5" fill="#FFF"/>';

        // Background Aura (Lvl 10+)
        string memory aura = attrs.level >= 10
            ? '<circle cx="175" cy="150" r="120" fill="none" stroke="#FFD700" stroke-width="2" stroke-dasharray="10" opacity="0.4"/>'
            : "";

        return string(
            abi.encodePacked(
                '<svg xmlns="http://www.w3.org/2000/svg" width="350" height="350" style="background:#0F0C29">',
                aura,
                // Body with dynamic rounding and color
                '<rect x="125" y="120" width="100" height="150" fill="',
                _getMainColor(attrs.level),
                '" stroke="#FFF" stroke-width="3" rx="20"/>',
                // Head
                '<circle cx="175" cy="80" r="40" fill="',
                _getMainColor(attrs.level),
                '" stroke="#FFF" stroke-width="3"/>',
                face,
                crown,
                // Modern Stats HUD
                '<rect x="25" y="280" width="300" height="55" rx="15" fill="rgba(255,255,255,0.05)"/>',
                '<text x="50" y="305" font-family="Verdana" font-size="14" fill="#00D4FF" font-weight="bold">LVL ',
                attrs.level.toString(),
                "</text>",
                '<text x="50" y="325" font-family="Verdana" font-size="11" fill="#AAA">STR: ',
                attrs.strength.toString(),
                " | HP: ",
                attrs.health.toString(),
                " | XP: ",
                attrs.experience.toString(),
                "</text>",
                "</svg>"
            )
        );
    }

    // --- Helper Styling Functions ---

    function _getMainColor(uint256 level) internal pure returns (string memory) {
        if (level >= 10) return "#1A1A1A"; // Elite Sleek Black
        if (level >= 5) return "#2980B9"; // Advanced Blue
        return "#7F8C8D"; // Starter Gray
    }

    function _getSecondaryColor(uint256 level) internal pure returns (string memory) {
        if (level >= 10) return "#FF4B2B"; // Power Red
        return "#00FBFF"; // Tech Cyan
    }

    // --- Standard Metadata Logic ---

    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        _requireOwned(tokenId);
        string memory svg = generateCharacterImage(tokenId);
        string memory imageURI = string(abi.encodePacked("data:image/svg+xml;base64,", Base64.encode(bytes(svg))));

        return string(
            abi.encodePacked(
                "data:application/json;base64,",
                Base64.encode(
                    bytes(
                        abi.encodePacked(
                            '{"name": "EvoBot #',
                            tokenId.toString(),
                            '", "description": "A character that evolves physically as it levels up.", "image": "',
                            imageURI,
                            '"}'
                        )
                    )
                )
            )
        );
    }

    // slither-disable-start weak-prng
    function _pseudoRandom(uint256 min, uint256 max, uint256 seed) private view returns (uint256) {
        // Using block.prevrandao and disabling the warning for this learning project
        return min + (uint256(keccak256(abi.encodePacked(block.prevrandao, msg.sender, seed))) % (max - min + 1));
    }
    // slither-disable-end weak-prng
}
