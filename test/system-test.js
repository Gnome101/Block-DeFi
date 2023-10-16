/* global describe it before ethers */
const hre = require("hardhat");
const { ethers } = require("hardhat");

const { assert } = require("chai");
const bigDecimal = require("js-big-decimal");

describe("System Test ", async function () {
  let test;

  before(async function () {
    accounts = await ethers.getSigners(); // could also do with getNamedAccounts
    deployer = accounts[0];
    user = accounts[1];
    await deployments.fixture(["SCROLL"]);
    await deployments.fixture(["ARBG"]);
  });

  it("can store numbers and read them Scroll", async () => {
    hre.changeNetwork("scrollSepolia");
    test = await ethers.getContractAt("Test");

    const num = await test.num();
    console.log(num.toString());
  });
  it("can store numbers and read them ARBG", async () => {
    hre.changeNetwork("arbgoerli");
    test = await ethers.getContractAt("Test");
    const num = await test.num();
    console.log(num.toString());
  });
});
