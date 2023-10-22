const { ethers } = require("hardhat");
async function main() {
  const hookFactory = await ethers.getContract("UniswapHooksFactory");
  const diamondAddress = await hookFactory.hooks(0);
  console.log(diamondAddress);
  hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
  instructionFacet = await ethers.getContractAt(
    "InstructionFacet",
    diamondAddress
  );
  managerFacet = await ethers.getContractAt("ManagerFacet", diamondAddress);

  // Test from arbGoerli to Scroll
  let instructions = [];
  instructions.push(await instructionFacet.instrucSetNumber());

  console.log(instructions);
  const packedInstructions =
    await managerFacet.convertBytes5ArrayToBytes(instructions);
  const instructionsWithInput = await managerFacet.addDataToFront(
    [5],
    packedInstructions
  );
  console.log(instructionsWithInput);
  await managerFacet.startWorking(instructionsWithInput);
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
