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
  console.log(diamondAddress);
  console.log("Failed");
  // let Diamond = await ethers.getContract("Diamond");
  // diamondAddress = Diamond.target;
  //Hyperlane

  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  let tx = await hyperFacet.setMailBox(hyperLaneData.MailBox);
  await tx.wait();
  tx = await hyperFacet.setGasMaster(hyperLaneData.GasPayMaster);
  await tx.wait();
  console.log("Now Compound");

  //Compound
  leverageFacet = await ethers.getContractAt("LeverageFacet", diamondAddress);
  tx = await leverageFacet.setComet(hyperLaneData.cometUSDC);
  await tx.wait();
  tx = await leverageFacet.setCometData(hyperLaneData.cometExt);
  await tx.wait();

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
    if (hyperLaneData.DBT) {
      console.log("HIU");
      await umaFacet.setCurrency(hyperLaneData.DBT);
    } else {
      await umaFacet.setCurrency(hyperLaneData.USDC);
    }
  }
  console.log("Now Wormhole");
  //Wormhole
  wormFacet = await ethers.getContractAt("WormFacet", diamondAddress);
  tx = await wormFacet.setWormHole(hyperLaneData.Wormhole);
  await tx.wait();
  tx = await wormFacet.setTokenBridge(hyperLaneData.TokenBridge);
  await tx.wait();
  tx = await wormFacet.setWormRelayer(hyperLaneData.Relayer);
  await tx.wait();

  //Uniswap
  uniswapFacet = await ethers.getContractAt("UniswapFacet", diamondAddress);
  tx = await uniswapFacet.setPoolManager(hyperLaneData.PoolManager);
  uniswapFacet = await ethers.getContractAt("UniswapFacet", diamondAddress);
};
module.exports.tags = ["all", "Test", "gyg"];
