// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/access/Ownable.sol";

contract UniversalReputation is Ownable {
    struct ReputationSource {
        string protocol;
        uint256 weight;
        bool active;
        uint256 lastUpdated;
    }

    struct ScoreRecord {
        uint256 score;
        uint256 timestamp;
        address updatedBy;
    }

    mapping(address => ReputationSource) public sources;
    address[] public sourceList;
    mapping(address => bool) public sourceExists;

    mapping(address => mapping(address => uint256)) public userScores;
    mapping(address => mapping(address => ScoreRecord[])) public scoreHistory;

    uint256 public maxScore = 1000;
    uint256 public totalWeight;

    event SourceAdded(address indexed protocol, uint256 weight);
    event SourceUpdated(address indexed protocol, uint256 newWeight);
    event ScoreUpdated(address indexed user, address indexed protocol, uint256 score);

    constructor() Ownable(msg.sender) {}

    function addReputationSource(address protocol, uint256 weight) external onlyOwner {
        require(!sourceExists[protocol], "Source exists");
        require(weight > 0, "Weight must be positive");

        sources[protocol] = ReputationSource({
            protocol: string(abi.encodePacked(protocol)),
            weight: weight,
            active: true,
            lastUpdated: block.timestamp
        });

        sourceList.push(protocol);
        sourceExists[protocol] = true;
        totalWeight += weight;

        emit SourceAdded(protocol, weight);
    }

    function updateScore(address user, address protocol, uint256 score) external onlyOwner {
        require(sourceExists[protocol], "Source not found");
        require(sources[protocol].active, "Source inactive");
        require(score <= maxScore, "Score exceeds max");

        userScores[user][protocol] = score;
        sources[protocol].lastUpdated = block.timestamp;

        scoreHistory[user][protocol].push(ScoreRecord({
            score: score,
            timestamp: block.timestamp,
            updatedBy: msg.sender
        }));

        emit ScoreUpdated(user, protocol, score);
    }

    function getAggregateScore(address user) external view returns (uint256) {
        uint256 weightedSum = 0;
        uint256 activeWeight = 0;

        for (uint256 i = 0; i < sourceList.length; i++) {
            address protocol = sourceList[i];
            if (sources[protocol].active) {
                weightedSum += userScores[user][protocol] * sources[protocol].weight;
                activeWeight += sources[protocol].weight;
            }
        }

        if (activeWeight == 0) return 0;
        return weightedSum / activeWeight;
    }

    function getProtocolScore(address user, address protocol) external view returns (uint256) {
        require(sourceExists[protocol], "Source not found");
        return userScores[user][protocol];
    }

    function getReputationHistory(address user, address protocol) external view returns (ScoreRecord[] memory) {
        return scoreHistory[user][protocol];
    }

    function getSourceCount() external view returns (uint256) {
        return sourceList.length;
    }

    function getSourceWeight(address protocol) external view returns (uint256) {
        require(sourceExists[protocol], "Source not found");
        return sources[protocol].weight;
    }

    function setSourceWeight(address protocol, uint256 newWeight) external onlyOwner {
        require(sourceExists[protocol], "Source not found");
        require(newWeight > 0, "Weight must be positive");
        totalWeight = totalWeight - sources[protocol].weight + newWeight;
        sources[protocol].weight = newWeight;
        emit SourceUpdated(protocol, newWeight);
    }

    function toggleSource(address protocol, bool active) external onlyOwner {
        require(sourceExists[protocol], "Source not found");
        sources[protocol].active = active;
    }

    function setMaxScore(uint256 _maxScore) external onlyOwner {
        require(_maxScore > 0, "Max must be positive");
        maxScore = _maxScore;
    }
}
