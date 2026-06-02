import hre from "hardhat";

async function main() {
  const { ethers } = await hre.network.connect();
  const [deployer] = await ethers.getSigners();
  const network = await ethers.provider.getNetwork();
  const chainId = Number(network.chainId);
  const networkName = chainId === 59141 ? "Linea" : chainId === 84532 ? "Base" : `Chain ${chainId}`;
  console.log(`Deploying to ${networkName} Sepolia (chainId: ${chainId})...`);
  console.log(`Deployer: ${deployer.address}`);
  const contracts = {};

  const UniversalReputationArtifact = await hre.artifacts.readArtifact("UniversalReputation");
  const urFactory = new ethers.ContractFactory(UniversalReputationArtifact.abi, UniversalReputationArtifact.bytecode, deployer);
  const universalReputation = await urFactory.deploy();
  await universalReputation.waitForDeployment();
  contracts.UniversalReputation = await universalReputation.getAddress();
  console.log(`  UniversalReputation: ${contracts.UniversalReputation}`);

  const ReputationOracleArtifact = await hre.artifacts.readArtifact("ReputationOracle");
  const roFactory = new ethers.ContractFactory(ReputationOracleArtifact.abi, ReputationOracleArtifact.bytecode, deployer);
  const reputationOracle = await roFactory.deploy(contracts.UniversalReputation);
  await reputationOracle.waitForDeployment();
  contracts.ReputationOracle = await reputationOracle.getAddress();
  console.log(`  ReputationOracle: ${contracts.ReputationOracle}`);

  const baseUrl = chainId === 59141 ? "https://sepolia.lineascan.build" : "https://sepolia.basescan.org";
  console.log(`\nVerify on ${networkName} Explorer:`);
  for (const [name, addr] of Object.entries(contracts)) {
    console.log(`  ${name}: ${baseUrl}/address/${addr}`);
  }
  console.log(JSON.stringify({ network: `${networkName.toLowerCase()}_sepolia`, chainId, deployer: deployer.address, contracts }, null, 2));
}

main().then(() => process.exit(0)).catch(e => { console.error(e); process.exit(1); });