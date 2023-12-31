const { network, ethers } = require("hardhat");
const { getData } = require("../../utils/Addresses");

async function main() {
  //const diamondAddress = await hookFactory.hooks(0);
  let Diamond = await ethers.getContract("Diamond");
  diamondAddress = Diamond.target;
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  //Scroll from arbgoerli network
  // const targetDomain = 534351;
  // const targetAddy = "0xE361bD876c95D608Ee2c97625CA32736030810d9";
  // //Mumbai from arbgoerli
  // const targetDomain = 80001;
  const targetAddy = "0xDbD0a46Bc529570Ab594b79A8f4467A6A6F289eA";

  //ArbGoerli from scroll network
  // const targetDomain = 421613;
  const hyperLaneData = getData(network.config.chainId);
  console.log(hyperLaneData);
  // const targetAddy = "0x837024764826ec6fdEF5c8a05F36F6cdb62B4759";
  // const igp = await hyperFacet.getQuote(80001, 100000);
  // console.log(igp.toString());
  // let targetAddy = "0x837024764826ec6fdEF5c8a05F36F6cdb62B4759";
  // let tx = await hyperFacet.setMailBox(hyperLaneData.MailBox);
  // await tx.wait();
  // tx = await hyperFacet.setGasMaster(hyperLaneData.GasPayMaster);
  // await tx.wait();
  // tx = await hyperFacet.setDomainToAddress(421613, targetAddy);
  // await tx.wait();
  emptyISM = await ethers.getContract("EmptyIsm");
  const n = await emptyISM.count();
  console.log(n.toString());
  // tx = await hyperFacet.setISM(emptyISM.target);
  // await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
