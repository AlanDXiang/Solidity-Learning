// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title GameCharacter
 * @dev A basic ERC721 NFT representing a game character
 * 
 * KEY DIFFERENCES FROM ERC20:
 * - Each token has a unique tokenId (not just a balance amount)
 * - We track WHO owns WHICH specific token
 * - Each token can have unique metadata/attributes
 */
contract GameCharacter is ERC721, Ownable {
    
    // ============================================
    // STATE VARIABLES
    // ============================================
    
    /**
     * @dev Counter for token IDs. Similar to how you might track 
     * total supply in ERC20, but here each increment creates a 
     * UNIQUE token, not just adding to a balance.
     */
    uint256 private _nextTokenId;
    
    /**
     * @dev Maximum supply of NFTs that can ever be minted.
     * Unlike ERC20 where supply is often flexible, NFT collections
     * usually have a fixed max supply (like 10,000 Bored Apes).
     */
    uint256 public constant MAX_SUPPLY = 1000;
    
    /**
     * @dev Struct to store character attributes.
     * This is what makes NFTs interesting - each one can have
     * unique properties stored on-chain!
     */
    struct CharacterAttributes {
        uint256 level;      // Character's current level (starts at 1)
        uint256 strength;   // Combat power
        uint256 health;     // Hit points
        uint256 experience; // XP earned
    }
    
    /**
     * @dev Mapping from tokenId => CharacterAttributes
     * 
     * COMPARE TO ERC20: In ERC20, you'd have mapping(address => uint256) 
     * to track balances. Here, we map tokenId to unique attributes.
     * 
     * Example: tokenAttributes[5] gives you the attributes of token #5
     */
    mapping(uint256 => CharacterAttributes) public tokenAttributes;
    
    // ============================================
    // EVENTS
    // ============================================
    
    /**
     * @dev Emitted when a new character is minted.
     * Events are CRUCIAL for frontend apps to track what's happening.
     */
    event CharacterMinted(
        address indexed owner, 
        uint256 indexed tokenId, 
        uint256 level,
        uint256 strength,
        uint256 health
    );
    
    // ============================================
    // CONSTRUCTOR
    // ============================================
    
    /**
     * @dev Constructor sets the NFT collection name and symbol.
     * 
     * COMPARE TO ERC20: Same concept! Your ERC20 had a name/symbol too.
     * Example: "GameCharacter" and "CHAR"
     */
    constructor() ERC721("GameCharacter", "CHAR") Ownable(msg.sender) {
        // Start token IDs at 1 (0 is often reserved/avoided in NFTs)
        _nextTokenId = 1;
    }
    
    // ============================================
    // CORE FUNCTIONS
    // ============================================
    
    /**
     * @dev Mint a new character NFT
     * 
     * KEY DIFFERENCE FROM ERC20:
     * - ERC20: mint(address, AMOUNT) - adds to their balance
     * - ERC721: mint(address) - creates ONE unique token for them
     * 
     * @param to The address that will own this NFT
     */
    function mint(address to) public {
        // Check we haven't hit max supply
        require(_nextTokenId <= MAX_SUPPLY, "Max supply reached");
        
        // Get the current token ID and increment for next mint
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        
        // Actually mint the NFT (this is the ERC721 standard function)
        // COMPARE: In ERC20, you did _mint(to, amount)
        //          In ERC721, you do _safeMint(to, tokenId)
        _safeMint(to, tokenId);
        
        // Initialize character attributes with random-ish starting stats
        // In a real game, you might make these truly random or user-chosen
        tokenAttributes[tokenId] = CharacterAttributes({
            level: 1,
            strength: _pseudoRandom(10, 20, tokenId), // Random 10-20
            health: _pseudoRandom(50, 100, tokenId),  // Random 50-100
            experience: 0
        });
        
        // Emit event for tracking
        emit CharacterMinted(
            to, 
            tokenId, 
            tokenAttributes[tokenId].level,
            tokenAttributes[tokenId].strength,
            tokenAttributes[tokenId].health
        );
    }
    
    /**
     * @dev Get the attributes of a specific token
     * 
     * @param tokenId The ID of the token to query
     * @return The CharacterAttributes struct for this token
     */
    function getCharacterAttributes(uint256 tokenId) 
        public 
        view 
        returns (CharacterAttributes memory) 
    {
        // Ensure the token exists
        require(_ownerOf(tokenId) != address(0), "Token does not exist");
        return tokenAttributes[tokenId];
    }
    
    /**
     * @dev Get total number of NFTs minted so far
     * 
     * COMPARE TO ERC20: Similar to totalSupply(), but here it's 
     * counting unique tokens, not a sum of balances.
     */
    function totalMinted() public view returns (uint256) {
        return _nextTokenId - 1;
    }
    
    // ============================================
    // HELPER FUNCTIONS
    // ============================================
    
    /**
     * @dev Simple pseudo-random number generator
     * ⚠️ WARNING: This is NOT secure! For production, use Chainlink VRF.
     * This is just for learning purposes.
     * 
     * @param min Minimum value
     * @param max Maximum value
     * @param seed A seed value for variation
     * @return A pseudo-random number between min and max
     */
    function _pseudoRandom(uint256 min, uint256 max, uint256 seed) 
        private 
        view 
        returns (uint256) 
    {
        uint256 randomHash = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender, seed))
        );
        return min + (randomHash % (max - min + 1));
    }
}
