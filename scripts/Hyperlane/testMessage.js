const { ethers } = require("hardhat");
async function main() {
  // const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Test from arbGoerli to Scroll

  let tx = await hyperFacet.hitEmUp(421613, 100000, "1200000000000000", {
    value: ethers.parseEther("0.01"),
  });
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
