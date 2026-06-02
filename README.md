# Reputation Score

> Universal reputation across DeFi protocols

Reputation Score aggregates a user's on-chain activity across multiple DeFi protocols into a single, portable reputation score. Lending history, governance participation, LP provision, and trading behavior are all factored into a universal credit score for the decentralized economy.

## On-Chain Proof

| Contract | Address |
|----------|---------|
| ReputationScore | `TBD` |
| ActivityAggregator | `TBD` |
| ScoreOracle | `TBD` |
| ProtocolRegistry | `TBD` |

Network: Ethereum Mainnet + L2 (Arbitrum, Optimism, Base, Polygon)

## How It Works

1. **Activity Tracking**: The ActivityAggregator monitors on-chain interactions across registered protocols—Aave, Uniswap, Compound, MakerDAO, ENS, and more. It records lending, borrowing, governance participation, and liquidity provision.

2. **Score Calculation**: The ReputationScore contract computes a composite score (0-1000) based on weighted factors: repayment history (30%), governance participation (20%), liquidity provision (20%), protocol diversity (15%), and account age (15%).

3. **Score Oracle**: The ScoreOracle publishes reputation scores on-chain, allowing any protocol to query a user's reputation. Scores update with each new qualifying on-chain action.

4. **Protocol Integration**: DeFi protocols integrate the ScoreOracle to offer reputation-based benefits—lower collateral requirements, higher borrowing limits, exclusive access, and reduced fees.

5. **Reputation Portability**: Users carry their reputation across all integrated protocols. A high reputation on Aave translates to benefits on Compound, Uniswap, and other participating platforms.

## Smart Contracts

```
contracts/
├── ReputationScore.sol            # Core scoring algorithm
├── ActivityAggregator.sol         # Multi-protocol activity tracking
├── ScoreOracle.sol                # On-chain score publication
├── ProtocolRegistry.sol           # Registered DeFi protocols
├── interfaces/
│   ├── IReputation.sol
│   └── IActivity.sol
└── libraries/
    ├── ScoreMath.sol
    └── WeightConfig.sol
```

### Key Features

- **Universal Score**: One reputation score aggregating activity across 20+ DeFi protocols.
- **Transparent Scoring**: All factors and weights are publicly auditable on-chain.
- **Protocol Integration**: Plug-and-play ScoreOracle for any DeFi protocol.
- **Cross-Chain**: Scores propagate across L2s and sidechains via cross-chain messaging.
- **Privacy Option**: ZK proofs allow reputation verification without exposing transaction history.

## Setup

### Prerequisites

- Node.js >= 18
- Foundry
- Wallet with testnet ETH

### Installation

```bash
git clone https://github.com/Souravjoy7/reputation-score.git
cd reputation-score
npm install
```

### Compile

```bash
forge build
```

### Test

```bash
forge test
```

### Deploy

```bash
forge script script/Deploy.s.sol --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast
```

### Environment Variables

```
RPC_URL=<your-rpc-url>
PRIVATE_KEY=<your-deployer-key>
ETHERSCAN_API_KEY=<your-etherscan-key>
GRAPH_ACCESS_TOKEN=<subgraph-access-token>
SCORE_UPDATE_INTERVAL=3600
```

## License

MIT License. See [LICENSE](LICENSE) for details.
