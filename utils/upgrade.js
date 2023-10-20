const { getSelectors, FacetCutAction } = require("./diamond");
const { network, ethers } = require("hardhat");

async function upgradeContract(facetName, diamondAddress, deploy) {
  console.log("Upgrading", facetName);
  let args = [];
  const facet = await ethers.getContract(facetName);
  let oldSelectors = getSelectors(facet);
  const diamondCutFacet = await ethers.getContractAt(
    "DiamondCutFacet",
    diamondAddress
  );

  tx = await diamondCutFacet.diamondCut(
    [
      {
        facetAddress: ethers.ZeroAddress.toString(),
        action: FacetCutAction.Remove,
        functionSelectors: oldSelectors,
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
}
exports.upgradeContract = upgradeContract;
