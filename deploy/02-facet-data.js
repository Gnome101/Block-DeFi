const { network, ethers } = require("hardhat");
//We need to use the selectors given to us by the gracious Nick Mudge
const { getData } = require("../utils/Addresses");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("Chain ID", network.config.chainId);
  const hyperLaneData = getData(network.config.chainId);
  console.log(hyperLaneData.Network);
  hookFactory = await ethers.getContract("UniswapHooksFactory");

  let diamondAddress = await hookFactory.hooks(0);
  // let Diamond = await ethers.getContract("Diamond");
  // diamondAddress = Diamond.target;
  //Hyperlane

  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  let tx = await hyperFacet.setMailBox(hyperLaneData.MailBox);
  await tx.wait();
  tx = await hyperFacet.setGasMaster(hyperLaneData.GasPayMaster);
  await tx.wait();

  //Compound
  leverageFacet = await ethers.getContractAt("LeverageFacet", diamondAddress);
  await leverageFacet.setComet(hyperLaneData.cometUSDC);
  await leverageFacet.setCometData(hyperLaneData.cometExt);

  //Spark
  if (hyperLaneData.SparkLend) {
    console.log("Howdy");
    sparkFacet = await ethers.getContractAt("SparkFacet", diamondAddress);
    await sparkFacet.setPool(hyperLaneData.SparkLend);
  }

  //UMA
  if (hyperLaneData.OOV3) {
    umaFacet = await ethers.getContractAt("UMAFacet", diamondAddress);
    await umaFacet.setOOV3(hyperLaneData.OOV3);
    await umaFacet.setCurrency(hyperLaneData.USDC);
  }

  //Wormhole
  wormFacet = await ethers.getContractAt("WormFacet", diamondAddress);
  await wormFacet.setWormHole(hyperLaneData.Wormhole);
  await wormFacet.setTokenBridge(hyperLaneData.TokenBridge);
  await wormFacet.setWormRelayer(hyperLaneData.Relayer);

  //Uniswap
  uniswapFacet = await ethers.getContractAt("UniswapFacet", diamondAddress);
  await uniswapFacet.setPoolManager(hyperLaneData.PoolManager);
};
module.exports.tags = ["all", "Test", "gyg"];
