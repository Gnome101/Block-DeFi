const { network, ethers } = require("hardhat");
//We need to use the selectors given to us by the gracious Nick Mudge
const { getSelectors, FacetCutAction } = require("../utils/diamond.js");
const { getSalt } = require("../utils/hookTools.js");

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

  const hyperFacet = await ethers.getContract("HyperFacet");
  facetCut.push({
    facetAddress: hyperFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(hyperFacet),
  });

  const leverageFacet = await ethers.getContract("LeverageFacet");
  facetCut.push({
    facetAddress: leverageFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(leverageFacet),
  });

  const managerFacet = await ethers.getContract("ManagerFacet");
  facetCut.push({
    facetAddress: managerFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(managerFacet),
  });

  const uniswapFacet = await ethers.getContract("UniswapFacet");
  facetCut.push({
    facetAddress: uniswapFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(uniswapFacet),
  });

  const hookFacet = await ethers.getContract("HookFacet");
  facetCut.push({
    facetAddress: hookFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(hookFacet),
  });

  const sparkFacet = await ethers.getContract("SparkFacet");
  facetCut.push({
    facetAddress: sparkFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(sparkFacet),
  });

  const instructionFacet = await ethers.getContract("InstructionFacet");
  facetCut.push({
    facetAddress: instructionFacet.target,
    action: FacetCutAction.Add,
    functionSelectors: getSelectors(instructionFacet),
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

  const hooksFactory = await ethers.getContract("UniswapHooksFactory");
  const salt = await getSalt(hooksFactory, facetCut, diamondArgs, 0x24);
  //const salt = 0;
  console.log("Le salt:", salt);
  // const Diamond = await deploy("Diamond", {
  //   from: deployer,
  //   args: args,
  //   log: true,
  //   blockConfirmations: 2,
  // });
  await hooksFactory.deploy(facetCut, diamondArgs, salt);
  console.log("Finished Deployment\n");
};
module.exports.tags = ["all", "Test", "ARBG"];
