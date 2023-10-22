const { ethers } = require("hardhat");
const { templatesPath } = require("rete-kit/bin/app/template-builder");
async function main() {
  const hookFactory = await ethers.getContract("UniswapHooksFactory");
  const diamondAddress = await hookFactory.hooks(0);
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  testFacet = await ethers.getContractAt("Test1Facet", diamondAddress);
  managerFacet = await ethers.getContractAt("ManagerFacet", diamondAddress);

  //Test from arbGoerli to Scroll
  let count = await hyperFacet.getCounter();
  console.log(count.toString());
  let number = await testFacet.getNumber();
  console.log(number.toString());
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
