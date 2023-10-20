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
  describe("Uniswap Tests", function () {
    beforeEach(async () => {
      //Before stuff
      //I need to mint 100 ETH from my test ETH
      //I need to swap 25 ETH for USDC
      //I need to swap 25 ETH for DAI
      //I need to add ETH/USDC liquidty to my v4 pool
    });
    it("can get weth and swap 121", async () => {
      const amount = ethers.parseEther("100");
      //formatEther divides by 10^18
      const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
      const WETH = await ethers.getContractAt("IWETH9", wethAddress);
      await WETH.deposit({ value: amount });
      console.log((await WETH.balanceOf(deployer.address)).toString());
    });
  });
});
