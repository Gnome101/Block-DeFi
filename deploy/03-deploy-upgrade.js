const { network, ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("../utils/diamond");
module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");

  const Diamond = await ethers.getContract("Diamond");
  const diamondAddress = Diamond.target;

  let args = [];
  const NewHyperFacet = await deploy("HyperFacet", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const hyperFacet = await ethers.getContract("HyperFacet");

  let selectors = getSelectors(hyperFacet);
  console.log(selectors);
  console.log(Diamond.target);
  const diamondCutFacet = await ethers.getContractAt(
    "DiamondCutFacet",
    diamondAddress
  );
  console.log(NewHyperFacet.address, ethers.ZeroAddress.toString());

  tx = await diamondCutFacet.diamondCut(
    [
      {
        facetAddress: NewHyperFacet.address,
        action: FacetCutAction.Add,
        functionSelectors: selectors,
      },
    ],
    ethers.ZeroAddress.toString(),
    "0x",
    { gasLimit: 800000 }
  );
  receipt = await tx.wait();
  if (!receipt.status) {
    throw Error(`Diamond upgrade failed: ${tx.hash}`);
  }
  log("------------------------------------------------------------");
};
module.exports.tags = ["FacetChange", "Upgrade"];
