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
  instructions.push(await instructionFacet.instrucSendFlowTokensGoerli());
  instructions.push(await instructionFacet.instrucGetNumber());
  console.log(instructions);
  const packedInstructions =
    await managerFacet.convertBytes5ArrayToBytes(instructions);
  let input = [
    (
      await managerFacet.convertAddyToNum(
        "0x8FB1E3fC51F3b789dED7557E680551d93Ea9d892"
      )
    ).toString(),
    "1000000",
  ];
  const instructionsWithInput = await managerFacet.addDataToFront(
    [7],
    packedInstructions
  );
  console.log(instructionsWithInput);
  await managerFacet.startWorking(instructionsWithInput);
}
main().catch((error) => {
  console.error(error);
  process.exit(1);
});
