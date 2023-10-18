const { ethers } = require("hardhat");
async function main() {
  // const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Test from arbGoerli to Scroll

  let tx = await hyperFacet.hitEmUp(534351, 50000, {
    value: ethers.parseEther("0.05"),
  });
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
