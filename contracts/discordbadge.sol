// SPDX-License-Identifier: MIT
// License identifier, required by Solidity file linter tools.
pragma solidity ^0.8.20;
// Specify the version of Solidity to compile with. This contract is written for 0.8.20+.

contract TaskFiBadge {
    // Human-readable name for the badge contract.
    // This is similar to the ERC-721 `name` field.
    string public name = " Badge";
    // Symbol for the badges, like a ticker symbol.
    string public symbol = "BADGE";
    
    // Monotonic counter used to generate new token IDs.
    // Every time a badge is minted, this counter increases.
    uint256 private _tokenIdCounter;
    
    // Mapping from token ID to owner address.
    // Used to look up who owns a given badge token.
    mapping(uint256 => address) private _owners;
    
    // Mapping from owner to the number of badges they own.
    mapping(address => uint256) private _balances;
    
    // Mapping from token ID to a string describing the badge type.
    mapping(uint256 => string) private _badgeTypes;
    
    // Tracks which addresses have been approved by the admin to receive a badge.
    mapping(address => bool) public isApproved;
    // Tracks whether an approved address has already minted their badge.
    mapping(address => bool) public hasMinted;
    
    // Address of the admin who can approve users and mint badges.
    address public admin;
    
    // Event emitted when a badge is minted to an address.
    event BadgeMinted(address indexed to, uint256 indexed tokenId, string badgeType);
    // Event emitted when an address is approved.
    event UserApproved(address indexed user);
    
    // Constructor runs once at deployment and sets the deployer as admin.
    constructor() {
        admin = msg.sender;
    }
    
    // Modifier that restricts access to admin-only functions.
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    /* -------------APPROVAL LOGIC ---------------- */  

    // Admin-only function to approve a user for badge minting.
    function approveUser(address user) external onlyAdmin {
        // Prevent the zero address from being approved.
        require(user != address(0), "Invalid address");
        // Prevent re-approving an already approved user.
        require(!isApproved[user], "User already approved");

        // Mark the user as approved.
        isApproved[user] = true;
        // Emit an event to record the approval on-chain.
        emit UserApproved(user);
    }
    
    // Mint a badge to an address
    function mintBadge(address to, string memory badgeType) public onlyAdmin {
        // Only approved users can have a badge minted for them.
        require(isApproved[to], "User not approved");
        // Each approved address can only mint once.
        require(!hasMinted[to], "User already minted a badge");
        
        // Generate a new token ID from the counter.
        uint256 tokenId = _tokenIdCounter;
        // Increment the counter for the next mint.
        _tokenIdCounter++;
        
        // Assign ownership of the new token.
        _owners[tokenId] = to;
        // Increase the recipient's badge count.
        _balances[to]++;
        // Store the type/name of this badge.
        _badgeTypes[tokenId] = badgeType;
        // Mark that this address has already minted one badge.
        hasMinted[to] = true;
        
        // Notify listeners that a badge has been minted.
        emit BadgeMinted(to, tokenId, badgeType);
    }
    
    /* -------------VIEW FUNCTIONS ----------------- */

    // Returns how many badges an address currently owns.
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    
    // Returns who owns a specific token.
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        // A token is considered to exist only if its owner is not the zero address.
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    
    // Returns the badge type string for a given token ID.
    function getBadgeType(uint256 tokenId) public view returns (string memory) {
        // Ensure the token exists before returning its associated badge type.
        require(_owners[tokenId] != address(0), "Token does not exist");
        return _badgeTypes[tokenId];
    }
    
    // Returns the total number of badges minted so far.
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }
}