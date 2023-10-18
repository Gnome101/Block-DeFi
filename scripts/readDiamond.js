const { ethers } = require("hardhat");
async function main() {
  //const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  diamondLoupeFacet = await ethers.getContractAt(
    "DiamondLoupeFacet",
    diamondAddress
  );
  console.log(
    await diamondLoupeFacet.facetFunctionSelectors(
      "0xbb6587566c3C7AA61a397C455487eD67FfF2d716"
    )
  );
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
