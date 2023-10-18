const { network, ethers } = require("hardhat");
const { getData } = require("../utils/Addresses");

async function main() {
  //const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Scroll from arbgoerli network
  // const targetDomain = 534351;
  // const targetAddy = "0xE361bD876c95D608Ee2c97625CA32736030810d9";
  //Mumbai from arbgoerli
  const targetDomain = 80001;
  const targetAddy = "0x837024764826ec6fdEF5c8a05F36F6cdb62B4759";

  //ArbGoerli from scroll network
  // const targetDomain = 421613;
  // const targetAddy = "0xff1f749f7Eaf9cFbd330440fCE21922bAA097fdE";

  let tx = await hyperFacet.setDomainToAddress(targetDomain, targetAddy);
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
