const { network } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  let args = [];
  console.log("Chain ID", network.config.chainId);

  //Deploying Facets
  const Test = await deploy("Test", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
};
module.exports.tags = ["all", "Test", "ARBG"];
