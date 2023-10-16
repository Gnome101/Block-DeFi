const { network } = require("hardhat");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  let args = [9990];
  console.log("Chain ID", network.config.chainId);

  //Deploying Test
  const Test = await deploy("Test", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
};
module.exports.tags = ["all", "Test", "ARBG"];
