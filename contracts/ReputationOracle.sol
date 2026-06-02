// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IUniversalReputation {
    function updateScore(address user, address protocol, uint256 score) external;
    function getProtocolScore(address user, address protocol) external view returns (uint256);
}

contract ReputationOracle is ReentrancyGuard, Ownable {
    enum VoteStatus { PENDING, ACCEPTED, REJECTED, DISPUTED }

    struct OracleRegistration {
        address oracleAddress;
        uint256 stake;
        bool active;
        uint256 registeredAt;
        uint256 submissionsCount;
    }

    struct ScoreSubmission {
        address user;
        uint256 score;
        bytes32 proofHash;
        address submitter;
        uint256 submittedAt;
        VoteStatus status;
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
    }

    IUniversalReputation public reputationContract;

    mapping(address => OracleRegistration) public oracles;
    address[] public oracleList;
    uint256 public oracleCounter;

    mapping(uint256 => ScoreSubmission) public submissions;
    uint256 public submissionCounter;
    uint256 public consensusThreshold = 51;
    uint256 public minOracles = 3;
    uint256 public votingPeriod = 24 hours;
    uint256 public minStake = 1 ether;

    event OracleRegistered(address indexed oracle, uint256 stake);
    event ScoreSubmitted(uint256 indexed submissionId, address indexed user, uint256 score);
    event VoteCast(uint256 indexed submissionId, address indexed voter, bool support);
    event SubmissionResolved(uint256 indexed submissionId, VoteStatus status);
    event DisputeRaised(uint256 indexed submissionId, address indexed disputer);

    constructor(address _reputationContract) Ownable(msg.sender) {
        reputationContract = IUniversalReputation(_reputationContract);
    }

    function registerOracle(uint256 stake) external payable {
        require(stake >= minStake, "Insufficient stake");
        require(!oracles[msg.sender].active, "Already registered");
        require(msg.value >= stake, "Insufficient payment");

        oracles[msg.sender] = OracleRegistration({
            oracleAddress: msg.sender,
            stake: stake,
            active: true,
            registeredAt: block.timestamp,
            submissionsCount: 0
        });

        oracleList.push(msg.sender);
        oracleCounter++;

        emit OracleRegistered(msg.sender, stake);
    }

    function submitScore(
        address user,
        uint256 score,
        bytes32 proofHash
    ) external onlyOracle returns (uint256) {
        require(score <= 1000, "Score too high");

        uint256 submissionId = submissionCounter++;
        ScoreSubmission storage sub = submissions[submissionId];
        sub.user = user;
        sub.score = score;
        sub.proofHash = proofHash;
        sub.submitter = msg.sender;
        sub.submittedAt = block.timestamp;
        sub.status = VoteStatus.PENDING;
        sub.votesFor = 0;
        sub.votesAgainst = 0;

        oracles[msg.sender].submissionsCount++;

        emit ScoreSubmitted(submissionId, user, score);
        return submissionId;
    }

    function vote(uint256 submissionId, bool support) external onlyOracle {
        ScoreSubmission storage submission = submissions[submissionId];
        require(submission.status == VoteStatus.PENDING, "Not pending");
        require(block.timestamp < submission.submittedAt + votingPeriod, "Voting ended");
        require(!submission.hasVoted[msg.sender], "Already voted");
        require(msg.sender != submission.submitter, "Cannot vote own submission");

        submission.hasVoted[msg.sender] = true;

        if (support) {
            submission.votesFor++;
        } else {
            submission.votesAgainst++;
        }

        emit VoteCast(submissionId, msg.sender, support);

        _checkConsensus(submissionId);
    }

    function _checkConsensus(uint256 submissionId) internal {
        ScoreSubmission storage submission = submissions[submissionId];
        uint256 totalVotes = submission.votesFor + submission.votesAgainst;

        if (totalVotes < minOracles) return;

        uint256 approvalRate = (submission.votesFor * 100) / totalVotes;

        if (approvalRate >= consensusThreshold) {
            submission.status = VoteStatus.ACCEPTED;
            reputationContract.updateScore(
                submission.user,
                msg.sender,
                submission.score
            );
            emit SubmissionResolved(submissionId, VoteStatus.ACCEPTED);
        } else if (submission.votesAgainst > submission.votesFor) {
            submission.status = VoteStatus.REJECTED;
            emit SubmissionResolved(submissionId, VoteStatus.REJECTED);
        }
    }

    function disputeScore(uint256 submissionId) external onlyOracle {
        ScoreSubmission storage submission = submissions[submissionId];
        require(submission.status == VoteStatus.PENDING, "Not disputable");

        submission.status = VoteStatus.DISPUTED;
        emit DisputeRaised(submissionId, msg.sender);
    }

    modifier onlyOracle() {
        require(oracles[msg.sender].active, "Not an oracle");
        _;
    }

    function getOracleCount() external view returns (uint256) {
        return oracleCounter;
    }

    function getSubmissionVotes(uint256 submissionId) external view returns (uint256 votesFor, uint256 votesAgainst) {
        ScoreSubmission storage submission = submissions[submissionId];
        return (submission.votesFor, submission.votesAgainst);
    }

    function getSubmissionStatus(uint256 submissionId) external view returns (VoteStatus) {
        return submissions[submissionId].status;
    }

    function setConsensusThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 50 && _threshold <= 100, "Invalid threshold");
        consensusThreshold = _threshold;
    }

    function setMinOracles(uint256 _min) external onlyOwner {
        require(_min > 0, "Must be positive");
        minOracles = _min;
    }

    function setVotingPeriod(uint256 _period) external onlyOwner {
        require(_period >= 1 hours, "Period too short");
        votingPeriod = _period;
    }

    function setMinStake(uint256 _stake) external onlyOwner {
        minStake = _stake;
    }

    function withdrawStake() external {
        OracleRegistration storage oracle = oracles[msg.sender];
        require(oracle.active, "Not active");
        require(oracle.submissionsCount == 0, "Outstanding submissions");

        oracle.active = false;
        uint256 stake = oracle.stake;
        oracle.stake = 0;

        payable(msg.sender).transfer(stake);
    }
}
