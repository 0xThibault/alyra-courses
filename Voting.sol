// SPDX-License-Identifier:MIT

pragma solidity ^0.8.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol";

contract Voting is Ownable {
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }
    
    struct Proposal {
        string description;
        uint voteCount;
    }
    
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationsStarted,
        ProposalsRegistrationsEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    
    event VoterRegistered(address voterAddress);
    event ProposalsRegistrationsStarted();
    event ProposalsRegistrationsEnded();
    event ProposalsRegistered(uint proposalId);
    event VotingSessionStarted();
    event VotingSessionEnded();
    event Voted(address voter, uint proposalId);
    event VotesTallied();
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    
    mapping(address => Voter) public whitelist;
    Proposal[] public proposals;
    WorkflowStatus status;
    uint winningProposalId;
    
    
    // Ajout des électeurs dans la whitelist
    function addVoter(address _address) public onlyOwner {
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.RegisteringVoters;
        require(!whitelist[_address].isRegistered, "This address is already registered.");
        
        whitelist[_address].isRegistered = true;
        
        emit VoterRegistered(_address);
        emit WorkflowStatusChange(oldStatus, status);
    }
    
    // Début de la session d'enregistrement des propositions
    function startProposalsRegistration() public onlyOwner {
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.ProposalsRegistrationsStarted;
        
        emit ProposalsRegistrationsStarted();
        emit WorkflowStatusChange(oldStatus, status);
    }
    
    // Les électeur inscrit sont autorisés à enregistrer leur propositions
    // pendant que la session d'enregistrement est active
    function addProposals(string memory _description) public {
        require(status == WorkflowStatus.ProposalsRegistrationsStarted, "The proposals registration is not active");
        require(whitelist[msg.sender].isRegistered == true, "You are not registered, you can't add proposal");
        
        proposals.push(Proposal({description: _description, voteCount: 0}));
        uint proposalId = proposals.length;
        
        emit ProposalsRegistered(proposalId);
    }
    
    // Fin de la session d'enregistrement des propositions
    function endProposalsRegistrations() public onlyOwner {
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.ProposalsRegistrationsEnded;
        
        emit ProposalsRegistrationsEnded();
        emit WorkflowStatusChange(oldStatus, status);
    }
    
    // Début de la session de vote
    function startVote() public onlyOwner {
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.VotingSessionStarted;
        
        emit VotingSessionStarted();
        emit WorkflowStatusChange(oldStatus, status);
    }
    
    // Les électeurs inscrit votent pour leur proposition préférée
    function addVote(uint _proposalId) public {
        require(status == WorkflowStatus.VotingSessionStarted, "The voting session is not active.");
        require(whitelist[msg.sender].isRegistered == true, "You are not registred, you can't vote.");
        require(whitelist[msg.sender].hasVoted == false, "You have already voted");
        
       
        proposals[_proposalId].voteCount += 1;
        whitelist[msg.sender].hasVoted = true;
        whitelist[msg.sender].votedProposalId = _proposalId;
        
        emit Voted(msg.sender, _proposalId);
    }
    
    // Fin de la session de vote
    function endVote() public onlyOwner {
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.VotingSessionEnded;
        
        emit VotingSessionEnded();
        emit WorkflowStatusChange(oldStatus, status);
    }
    
    // Calcul des votes
    function winningProposal() public onlyOwner {
        WorkflowStatus oldStatus = status;
        status = WorkflowStatus.VotesTallied;
        
        uint winningVoteCount = 0;
        for (uint i; i < proposals.length; i++) {
            if (proposals[i].voteCount > winningVoteCount) {
                winningVoteCount = proposals[i].voteCount;
                winningProposalId = i;
            }
        }
        
        emit VotesTallied();
        emit WorkflowStatusChange(oldStatus, status);
    }
    
    // Montrer les détails de la proposition gagnante
    function showWinner() public view returns (string memory _description) {
        _description = proposals[winningProposalId].description;
    }
    
}