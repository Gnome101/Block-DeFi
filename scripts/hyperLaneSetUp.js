const { network, ethers } = require("hardhat");
const { getData } = require("../utils/Addresses");

async function main() {
  //const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Scroll from arbgoerli network
  // const targetDomain = 534351;
  // const targetAddy = "0xF5A235DC0d413FecBf15D5008F27Ed3F937f9f52";

  //ArbGoerli from scroll network
  const targetDomain = 421613;
  const targetAddy = "0x01f4C28329eeB4F5E72D31aDf9b2b636B2270104";

  let tx = await hyperFacet.setDomainToAddress(targetDomain, targetAddy);
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
