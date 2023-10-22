const { ethers } = require("hardhat");
async function main() {
  const hookFactory = await ethers.getContract("UniswapHooksFactory");
  const diamondAddress = await hookFactory.hooks(0);
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Test from arbGoerli to Scroll
  let args = [0];
  let tx = await hyperFacet.hitEmUp(5, 100000, "1200000000000000", {
    value: ethers.parseEther("0.007"),
  });
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
