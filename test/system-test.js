/* global describe it before ethers */
const { ethers } = require("hardhat");

const { assert } = require("chai");
const bigDecimal = require("js-big-decimal");

describe("System Test ", async function () {
  let test;

  before(async function () {
    accounts = await ethers.getSigners(); // could also do with getNamedAccounts
    deployer = accounts[0];
    user = accounts[1];
    await deployments.fixture(["all"]);
  });

  it("can store numbers and read them", async () => {
    test = await ethers.getContract("Test");

    const num = await test.num();
    console.log(num.toString());
  });
});
