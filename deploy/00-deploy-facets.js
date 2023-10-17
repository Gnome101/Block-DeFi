const { network, ethers } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  let args = [];
  console.log("Chain ID", network.config.chainId);
  //Deploying DiamondInit
  const DiamondInit = await deploy("DiamondInit", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  //Deploying Facets
  const DiamondCutFacet = await deploy("DiamondCutFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
  const DiamondLoupeFacet = await deploy("DiamondLoupeFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const OwnershipFacet = await deploy("OwnershipFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const Test1 = await deploy("Test1Facet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
};
module.exports.tags = ["all", "Facets"];
