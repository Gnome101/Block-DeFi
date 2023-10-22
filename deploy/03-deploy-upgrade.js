const { network, ethers } = require("hardhat");
const { getSelectors, FacetCutAction } = require("../utils/diamond");
const { upgradeContract } = require("../utils/upgrade");
module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  log("------------------------------------------------------------");
  const facetName = "HyperFacet";
  hookFactory = await ethers.getContract("UniswapHooksFactory");

  let diamondAddress = await hookFactory.hooks(0);
  console.log(diamondAddress);
  console.log("Upgrading", facetName);
  let args = [];

  const diamondCutFacet = await ethers.getContractAt(
    "DiamondCutFacet",
    diamondAddress
  );
  // const facet = await ethers.getContract(facetName);
  // let oldSelectors = getSelectors(facet);
  // console.log(oldSelectors);

  // tx = await diamondCutFacet.diamondCut(
  //   [
  //     {
  //       facetAddress: ethers.ZeroAddress.toString(),
  //       action: FacetCutAction.Remove,
  //       functionSelectors: oldSelectors,
  //     },
  //   ],
  //   ethers.ZeroAddress.toString(),
  //   "0x",
  //   { gasLimit: 800000 }
  // );
  // receipt = await tx.wait();
  // if (!receipt.status) {
  //   throw Error(`Diamond upgrade failed: ${tx.hash}`);
  // }
  const NewFacet = await deploy(facetName, {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });

  const newFacet = await ethers.getContract(facetName);
  let selectors = getSelectors(newFacet);
  tx = await diamondCutFacet.diamondCut(
    [
      {
        facetAddress: NewFacet.address,
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
