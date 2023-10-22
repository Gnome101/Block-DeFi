const { network, ethers } = require("hardhat");
const { getData } = require("../utils/Addresses");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");

  console.log("Chain ID", network.config.chainId);
  const hyperLaneData = getData(network.config.chainId);
  console.log(hyperLaneData);
  let args = [
    hyperLaneData.Relayer,
    hyperLaneData.TokenBridge,
    hyperLaneData.Wormhole,
  ];
  const WormFacet = await deploy("WormFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
};
module.exports.tags = ["Facets", "Worm"];
