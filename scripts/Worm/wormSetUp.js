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
  const cost = await wormFacet.quoteCrossChainDeposit(23);
  console.log(cost.toString());
  //0x9c3C9283D3e44854697Cd22D3Faa240Cfb032889 is WMATIC
  let decimalAdj = Decimal.pow(10, 18);
  const maticAmount = new Decimal(0.05).times(decimalAdj);

  let tx = await WMATIC.approve(wormFacet.target, maticAmount.toFixed());
  await tx.wait();
  tx = await wormFacet.sendCrossChainDeposit(
    23,
    "0x5E06Fc99Ee9dD15740D5397d8F9F511027663c34",
    maticAmount.toFixed(),
    WMATIC.target,
    {
      value: cost.toString(),
    }
  );
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
