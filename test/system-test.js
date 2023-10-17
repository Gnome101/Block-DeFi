/* global describe it before ethers */
const { ethers } = require("hardhat");

const { assert } = require("chai");
const bigDecimal = require("js-big-decimal");

describe("System Test ", async function () {
  let Diamond;
  let testFacet;
  let hookFactory;
  before(async function () {
    accounts = await ethers.getNamedSigners(); // could also do with getNamedAccounts
    deployer = accounts[0];
    user = accounts[1];
    await deployments.fixture(["all"]);
    hookFactory = await ethers.getContract("UniswapHooksFactory");
    const diamondHook = await hookFactory.hooks(0);

    const diamondAddress = diamondHook;
    testFacet = await ethers.getContractAt("Test1Facet", diamondAddress);
  });

  it("can store numbers and read them", async () => {
    await testFacet.setNum("3");
    const num = await testFacet.num();
    console.log(num.toString());
  });
});
