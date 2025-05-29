// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract DecentralizedVotingSystem {
    struct Proposal {
        uint256 id;
        string title;
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
        address proposer;
    }
    
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint256 votedProposalId;
    }
    
    address public admin;
    uint256 public proposalCount;
    uint256 public voterCount;
    
    mapping(uint256 => Proposal) public proposals;
    mapping(address => Voter) public voters;
    mapping(uint256 => mapping(address => bool)) public votes;
    
    event VoterRegistered(address indexed voter);
    event ProposalCreated(uint256 indexed proposalId, string title, address indexed proposer);
    event VoteCasted(address indexed voter, uint256 indexed proposalId);
    event ProposalExecuted(uint256 indexed proposalId);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin can perform this action");
        _;
    }
    
    modifier onlyRegisteredVoter() {
        require(voters[msg.sender].isRegistered, "You must be a registered voter");
        _;
    }
    
    modifier proposalExists(uint256 _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposalCount, "Proposal does not exist");
        _;
    }
    
    constructor() {
        admin = msg.sender;
        proposalCount = 0;
        voterCount = 0;
    }
    
    // Core Function 1: Register voters
    function registerVoter(address _voter) external onlyAdmin {
        require(!voters[_voter].isRegistered, "Voter is already registered");
        require(_voter != address(0), "Invalid voter address");
        
        voters[_voter] = Voter({
            isRegistered: true,
            hasVoted: false,
            votedProposalId: 0
        });
        
        voterCount++;
        emit VoterRegistered(_voter);
    }
    
    // Core Function 2: Create proposals
    function createProposal(
        string memory _title, 
        string memory _description, 
        uint256 _durationInDays
    ) external onlyRegisteredVoter {
        require(bytes(_title).length > 0, "Title cannot be empty");
        require(bytes(_description).length > 0, "Description cannot be empty");
        require(_durationInDays > 0, "Duration must be greater than 0");
        
        proposalCount++;
        uint256 deadline = block.timestamp + (_durationInDays * 1 days);
        
        proposals[proposalCount] = Proposal({
            id: proposalCount,
            title: _title,
            description: _description,
            voteCount: 0,
            deadline: deadline,
            executed: false,
            proposer: msg.sender
        });
        
        emit ProposalCreated(proposalCount, _title, msg.sender);
    }
    
    // Core Function 3: Cast votes
    function vote(uint256 _proposalId) external onlyRegisteredVoter proposalExists(_proposalId) {
        require(!voters[msg.sender].hasVoted, "You have already voted");
        require(block.timestamp <= proposals[_proposalId].deadline, "Voting period has ended");
        require(!proposals[_proposalId].executed, "Proposal has been executed");
        require(!votes[_proposalId][msg.sender], "You have already voted for this proposal");
        
        votes[_proposalId][msg.sender] = true;
        voters[msg.sender].hasVoted = true;
        voters[msg.sender].votedProposalId = _proposalId;
        proposals[_proposalId].voteCount++;
        
        emit VoteCasted(msg.sender, _proposalId);
    }
    
    // Additional utility functions
    function getProposal(uint256 _proposalId) external view proposalExists(_proposalId) returns (
        uint256 id,
        string memory title,
        string memory description,
        uint256 voteCount,
        uint256 deadline,
        bool executed,
        address proposer
    ) {
        Proposal memory proposal = proposals[_proposalId];
        return (
            proposal.id,
            proposal.title,
            proposal.description,
            proposal.voteCount,
            proposal.deadline,
            proposal.executed,
            proposal.proposer
        );
    }
    
    function getVoterInfo(address _voter) external view returns (
        bool isRegistered,
        bool hasVoted,
        uint256 votedProposalId
    ) {
        Voter memory voter = voters[_voter];
        return (voter.isRegistered, voter.hasVoted, voter.votedProposalId);
    }
    
    function isVotingActive(uint256 _proposalId) external view proposalExists(_proposalId) returns (bool) {
        return block.timestamp <= proposals[_proposalId].deadline && !proposals[_proposalId].executed;
    }
    
    function executeProposal(uint256 _proposalId) external onlyAdmin proposalExists(_proposalId) {
        require(block.timestamp > proposals[_proposalId].deadline, "Voting period is still active");
        require(!proposals[_proposalId].executed, "Proposal has already been executed");
        
        proposals[_proposalId].executed = true;
        emit ProposalExecuted(_proposalId);
    }
}
