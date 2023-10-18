const { ethers } = require("hardhat");
async function main() {
  //const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Test from arbGoerli to Scroll
  let count = await hyperFacet.getCounter();
  console.log(count.toString());
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
