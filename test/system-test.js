/* global describe it before ethers */
const { ethers } = require("hardhat");

const { assert } = require("chai");
const bigDecimal = require("js-big-decimal");

describe("System Test ", async function () {
  let Diamond;
  let testFacet;
  let hookFactory;
  let hyperFacet;
  let uniswapFacet;
  let leverageFacet;
  let deployer;
  let user;
  let poolManager;
  let DAI;
  let WETH;
  let USDC;

  before(async function () {
    accounts = await ethers.getNamedSigners(); // could also do with getNamedAccounts
    deployer = accounts.deployer;
    user = accounts.user;
    await deployments.fixture(["all"]);
    hookFactory = await ethers.getContract("UniswapHooksFactory");
    //let diamondAddress = await hookFactory.hooks(0);

    Diamond = await ethers.getContract("Diamond");
    diamondAddress = Diamond.target;
    testFacet = await ethers.getContractAt("Test1Facet", diamondAddress);
    hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
    uniswapFacet = await ethers.getContractAt("UniswapFacet", diamondAddress);
    leverageFacet = await ethers.getContractAt("LeverageFacet", diamondAddress);
    poolManager = await ethers.getContract("PoolManager");
    const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    WETH = await ethers.getContractAt("IWETH9", wethAddress);

    const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    USDC = await ethers.getContractAt("IERC20", usdcAddress);

    const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    DAI = await ethers.getContractAt("IERC20", daiAddress);
  });

  it("can store numbers and read them", async () => {
    await testFacet.setNum("3");
    const num = await testFacet.num();
    console.log(num.toString());
  });
  it("can read counter", async () => {
    let c = await hyperFacet.getCounter();
    console.log(c.toString());
  });
  it("can get weth and swap ", async () => {
    const amount = ethers.parseEther("100");
    //formatEther divides by 10^18
    console.log(amount.toString());

    await WETH.deposit({ value: amount });
    console.log(
      "WETH Balance:",
      (await WETH.balanceOf(deployer.address)).toString()
    );
    const swapAddy = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
    //Create swapRouter to interact with
    const swapAmount = ethers.parseEther("25");
    const swapRouter = await ethers.getContractAt("ISwapRouter", swapAddy);
    let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
    await WETH.approve(swapAddy, swapAmount.toString());
    let ExactInputSingleParams = {
      tokenIn: WETH.target,
      tokenOut: USDC.target,
      fee: "3000",
      recipient: deployer.address,
      deadline: timeStamp + 10000, //Timestamp is in seconds
      amountIn: swapAmount,
      amountOutMinimum: 0,
      sqrtPriceLimitX96: 0,
    };
    await swapRouter.exactInputSingle(ExactInputSingleParams);
    console.log(
      "USDC Balance:",
      (await USDC.balanceOf(deployer.address)).toString()
    );
    await WETH.approve(swapAddy, swapAmount.toString());
    ExactInputSingleParams.tokenOut = DAI.target;
    await swapRouter.exactInputSingle(ExactInputSingleParams);
    console.log(
      "DAI Balance:",
      (await DAI.balanceOf(deployer.address)).toString()
    );
  });
  describe("Uniswap Tests", function () {
    beforeEach(async () => {
      const amount = ethers.parseEther("100");
      //formatEther divides by 10^18
      console.log(amount.toString());

      await WETH.deposit({ value: amount });
      console.log(
        "WETH Balance:",
        (await WETH.balanceOf(deployer.address)).toString()
      );
      const swapAddy = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
      //Create swapRouter to interact with
      const swapAmount = ethers.parseEther("25");
      const swapRouter = await ethers.getContractAt("ISwapRouter", swapAddy);
      let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
      await WETH.approve(swapAddy, swapAmount.toString());
      let ExactInputSingleParams = {
        tokenIn: WETH.target,
        tokenOut: USDC.target,
        fee: "3000",
        recipient: deployer.address,
        deadline: timeStamp + 10000, //Timestamp is in seconds
        amountIn: swapAmount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0,
      };
      await swapRouter.exactInputSingle(ExactInputSingleParams);
      console.log(
        "USDC Balance:",
        (await USDC.balanceOf(deployer.address)).toString()
      );
      await WETH.approve(swapAddy, swapAmount.toString());
      ExactInputSingleParams.tokenOut = DAI.target;
      await swapRouter.exactInputSingle(ExactInputSingleParams);
      console.log(
        "DAI Balance:",
        (await DAI.balanceOf(deployer.address)).toString()
      );
    });
    it("can add liquidty and initialze a pool 211", async () => {
      //I need to add ETH/USDC liquidty to my v4 pool
      //First, initailze pool, addys must be sorted
      let addresses = [WETH.target, USDC.target];
      addresses.sort();
      const hook = "0x0000000000000000000000000000000000000000";
      const poolKey = {
        currency0: adresses[0].toString().trim(),
        currency1: adresses[1].toString().trim(),
        fee: "3000",
        tickSpacing: "60",
        hooks: hook,
      };
    });
  });
});
