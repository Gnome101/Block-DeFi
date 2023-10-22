const { network, ethers } = require("hardhat");
const { getData } = require("../../utils/Addresses");
const Decimal = require("decimal.js");

async function main() {
  let wormFacet = await ethers.getContract("WormFacet");
  const wmaticAddy = "0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889";

  let WMATIC = await ethers.getContractAt(
    "contracts/WormHole/interfaces/IERC20.sol:IERC20",
    wmaticAddy
  );
  const count = await wormFacet.counter();
  const lastSender = await wormFacet.sender();

  console.log(count, lastSender);
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
