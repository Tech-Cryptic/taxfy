// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TaskFiBadge {
  // It states the taskfi proof of work badge
    string public name = "TaskFi Proof of Work Badge";
    // The badge symbol
    string public symbol = "TASKFI";                          

    //This is the identifer of the minted token
    uint256 private _tokenIdCounter;

    //Structure for the user and their badge token
    struct UserProfile {
        string username;
        uint256 badgeTokenId;
    }

    // Structure for how CompletedJob will be showen on the blockchain.
    struct CompletedJob { // variable
        string title;            //Job title
        uint256 date;            // Date completed
        address client;          // Client who paid (optional)
        uint256 amountPaid;      // Amount paid (optitonal)
        uint8 rating;            // Rsting recived 
        uint256 receiptId;       // Receipt number
    }

     // Mapping from token ID to owner address.
    // Used to look up who owns a given badge token.
    mapping(uint256 => address) private _owners;
     // Mapping from owner to the number of badges they own (will always be 0 or 1 per address)
    mapping(address => uint256) private _balances;
     // Tracks which addresses the admin has approved to mint a badge
    mapping(address => bool) public isApproved;
    // Tracks which addresses have already minted their badge (prevents double minting)
    mapping(address => bool) public hasMinted;
    // Maps each wallet address → their UserProfile (username + token ID)
    mapping(address => UserProfile) private _profiles;
     // Maps each freelancer's wallet → their full array of completed jobs
    mapping(address => CompletedJob[]) private _jobHistory;

    //  Admin

    // The wallet that deployed this contract. Only the admin can approve users,
    // mint badges, and add job records.
    address public admin;


    // Emitted when a badge is successfully minted to a freelancer
    event BadgeMinted(address indexed to, uint256 indexed tokenId);
      // Emitted when a completed job is added to a freelancer's record
    event JobAdded(address indexed freelancer, uint256 receiptId);
    // Emitted when the admin approves a new user to mint a badge
    event UserApproved(address indexed user);

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can call this");
        _;
    }

    function approveUser(address user) external onlyAdmin {
        require(user != address(0), "Invalid address");            // Reject zero/null address
        require(!isApproved[user], "User already approved");       // Prevent duplicate approval
        isApproved[user] = true;
        emit UserApproved(user);
    }

    function mintBadge(address to, string memory username) public onlyAdmin {
        require(isApproved[to], "User not approved");                    // Must be approved first
        require(!hasMinted[to], "User already minted a badge");         //  One badge per user

            // Assign the current counter value as this token's unique ID
        uint256 tokenId = _tokenIdCounter;
        _tokenIdCounter++;      // Increment counter for the next mint

        // Register ownership of this token
        _owners[tokenId] = to;
        _balances[to]++;
            // Save the freelancer's profile on-chain
        _profiles[to] = UserProfile({ username: username, badgeTokenId: tokenId });

        // Mark this address as having minted — blocks future mints
        hasMinted[to] = true;

        emit BadgeMinted(to, tokenId);
    }

    function addCompletedJob(
        address to,
        string memory title,
        uint256 date,
        address client,
        uint256 amountPaid,
        uint8 rating,
        uint256 receiptId
    ) public onlyAdmin {
         // Enforce valid rating range before writing anything to state
        require(rating >= 1 && rating <= 5, "Rating must be between 1 and 5");


                // Push the new job record into the freelancer's history array
        _jobHistory[to].push(CompletedJob({
            title: title,
            date: date,
            client: client,
            amountPaid: amountPaid,
            rating: rating,
            receiptId: receiptId
        }));
        emit JobAdded(to, receiptId);
    }
    /**
     *  Returns the full list of completed jobs for a given freelancer.
     *  Returns an empty array if the address has no job history yet.
     *  owner The freelancer's wallet address.
     */
    function getJobHistory(address owner) public view returns (CompletedJob[] memory) {
        return _jobHistory[owner];
    }
    /**
     *  Returns how many badges a given address holds (0 or 1).
     *  owner The wallet address to check.
     */
    function balanceOf(address owner) public view returns (uint256) {
        return _balances[owner];
    }
    /**
     *  Returns the wallet address that owns a given token ID.
     *  Reverts if the token ID has never been minted (owner is zero address).
     *  tokenId The token ID to look up.
     */
    function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "Token does not exist");
        return owner;
    }
    /**
     *  Returns the total number of badges minted so far.
     *  Since _tokenIdCounter increments on every mint, it always equals total supply.
     */
    function totalSupply() public view returns (uint256) {
        return _tokenIdCounter;
    }
}