const { network, ethers } = require("hardhat");
//We need to use the selectors given to us by the gracious Nick Mudge
const { getData } = require("../utils/Addresses");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("Chain ID", network.config.chainId);
  const hyperLaneData = getData(network.config.chainId);
  console.log(hyperLaneData);
  hookFactory = await ethers.getContract("UniswapHooksFactory");
  emptyISM = await ethers.getContract("EmptyIsm");

  const diamondAddress = await hookFactory.hooks(0);

  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  await hyperFacet.setMailBox(hyperLaneData.MailBox);
  await hyperFacet.setGasMaster(hyperLaneData.GasPayMaster);
  await hyperFacet.setISM(emptyISM.target);
};
module.exports.tags = ["all", "Test", "gyg"];
