const { network, ethers } = require("hardhat");
//We need to use the selectors given to us by the gracious Nick Mudge
const { getSelectors, FacetCutAction } = require("../utils/diamond.js");

module.exports = async function ({ getNamedAccounts, deployments }) {
  const { deploy, log } = deployments;
  const { deployer } = await getNamedAccounts();
  console.log("Chain ID", network.config.chainId);
  log("------------------------------------------------------------");
  let args = [];
  //This is a list of all of the facets we are adding
  let facetCut = [];

  const diamondInit = await ethers.getContract("DiamondInit");

  const diamondCutFacet = await ethers.getContract("DiamondCutFacet");
  facetCut.push({
    facetAddress: diamondCutFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(diamondCutFacet),
  });

  const diamondLoupeFacet = await ethers.getContract("DiamondLoupeFacet");
  facetCut.push({
    facetAddress: diamondLoupeFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(diamondLoupeFacet),
  });

  const ownershipFacet = await ethers.getContract("OwnershipFacet");
  facetCut.push({
    facetAddress: ownershipFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(ownershipFacet),
  });

  const test1 = await ethers.getContract("Test1Facet");
  facetCut.push({
    facetAddress: test1.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(test1),
  });
  //Now that all of the facets and their cut data is organized we continue
  let functionCall = diamondInit.interface.encodeFunctionData("init");

  const diamondArgs = {
    owner: deployer,
    init: diamondInit.target,
    initCalldata: functionCall,
  };
  //Deploying Diamond
  args = [facetCut, diamondArgs];
  const Diamond = await deploy("Diamond", {
    from: deployer,
    args: args,
    log: true,
    blockConfirmations: 2,
  });
  console.log("Finished Deployment\n");
};
module.exports.tags = ["all", "Test", "ARBG"];
