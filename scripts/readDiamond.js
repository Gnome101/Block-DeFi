const { ethers } = require("hardhat");
async function main() {
  //const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  diamondLoupeFacet = await ethers.getContractAt(
    "DiamondLoupeFacet",
    diamondAddress
  );
  console.log(await diamondLoupeFacet.facetAddresses());
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
