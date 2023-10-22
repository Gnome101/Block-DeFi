const { network, ethers } = require("hardhat");

async function main() {
  const hookFactory = await ethers.getContract("UniswapHooksFactory");
  const diamondAddress = await hookFactory.hooks(0);
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  wormFacet = await ethers.getContractAt("WormFacet", diamondAddress);

  let tx = await hyperFacet.setDomainToAddress(
    5,
    "0x24453997F37f29Fb23B0D9eE22141f1eC05AE420"
  ); //USDC
  await tx.wait();
  tx = await hyperFacet.setDomainToAddress(
    421613,
    "0x249857791a5Ac865C7F4bB56eE6EBa6864B9ecc8"
  ); //ARB GOERLI
  await tx.wait();
  tx = await wormFacet.setAddyForDomain(
    2,
    "0x24453997F37f29Fb23B0D9eE22141f1eC05AE420"
  ); //USDC
  await tx.wait();

  tx = await wormFacet.setAddyForDomain(
    23,
    "0x249857791a5Ac865C7F4bB56eE6EBa6864B9ecc8"
  ); //ARB GOERLI
  await tx.wait();
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
