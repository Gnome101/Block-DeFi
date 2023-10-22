const { ethers } = require("hardhat");
async function main() {
  const hookFactory = await ethers.getContract("UniswapHooksFactory");
  const diamondAddress = await hookFactory.hooks(0);
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
