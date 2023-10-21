const { network, ethers } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  let args = [];
  console.log("Chain ID", network.config.chainId);
  //Deploy Pool Manager (Big Boy!!)
  args = [500000];
  const PoolManager = await deploy("PoolManager", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
  args = [];
  //Deploying Hook-Factory
  const UniswapHooksFactory = await deploy("UniswapHooksFactory", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

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
  const EmptyIsm = await deploy("EmptyIsm", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const HyperFacet = await deploy("HyperFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const LeverageFacet = await deploy("LeverageFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const ManagerFacet = await deploy("ManagerFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const UniswapFacet = await deploy("UniswapFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const HookFacet = await deploy("HookFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const SparkFacet = await deploy("SparkFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const InstructionFacet = await deploy("InstructionFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const ControlFacet = await deploy("ControlFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
};
module.exports.tags = ["all", "Facets"];
