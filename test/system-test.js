/* global describe it before ethers */
const { network, ethers } = require("hardhat");
const {
  calculateSqrtPriceX96,
  getNearestUsableTick,
} = require("../utils/uniswapCalculations");
const { assert } = require("chai");
const Decimal = require("decimal.js");
const { getData } = require("../utils/Addresses");

describe("System Test ", async function () {
  let Diamond;
  let testFacet;
  let hookFactory;
  let hyperFacet;
  let uniswapFacet;
  let leverageFacet;
  let sparkFacet;
  let managerFacet;
  let instructionFacet;
  let umaFacet;
  let diamondAddress;
  let deployer;
  let user;
  let poolManager;
  let DAI;
  let WETH;
  let USDC;
  let Comet;
  let CometData;
  let networkData;
  let wstETH;
  let DBT;
  beforeEach(async function () {
    accounts = await ethers.getNamedSigners(); // could also do with getNamedAccounts
    deployer = accounts.deployer;
    user = accounts.user;
    //await deployments.fixture(["all"]);
    //hookFactory = await ethers.getContract("UniswapHooksFactory");
    diamondAddress = "0x24e229c25bfac1999f5F03Fd9EbD5ab3913534a8";
    //diamondAddress = await hookFactory.hooks(0);

    //Diamond = await ethers.getContract("Diamond");
    //diamondAddress = Diamond.target;
    networkData = getData(network.config.chainId);
    poolManager = await ethers.getContractAt(
      "PoolManager",
      networkData.PoolManager
    );
    testFacet = await ethers.getContractAt("Test1Facet", diamondAddress);
    hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
    uniswapFacet = await ethers.getContractAt("UniswapFacet", diamondAddress);
    hookFacet = await ethers.getContractAt("HookFacet", diamondAddress);
    managerFacet = await ethers.getContractAt("ManagerFacet", diamondAddress);
    umaFacet = await ethers.getContractAt("UMAFacet", diamondAddress);
    instructionFacet = await ethers.getContractAt(
      "InstructionFacet",
      diamondAddress
    );
    sparkFacet = await ethers.getContractAt("SparkFacet", diamondAddress);

    leverageFacet = await ethers.getContractAt("LeverageFacet", diamondAddress);

    Comet = await ethers.getContractAt(
      "CometMainInterface",
      networkData.cometUSDC
    );
    CometData = await ethers.getContractAt(
      "CometExtInterface",
      networkData.cometExt
    );

    WETH = await ethers.getContractAt("IWETH9", networkData.WETH);

    USDC = await ethers.getContractAt(
      "contracts/WormHole/interfaces/IERC20.sol:IERC20",
      networkData.USDC
    );
    if (networkData.wstETH) {
      wstETH = await ethers.getContractAt(
        "contracts/WormHole/interfaces/IERC20.sol:IERC20",
        networkData.wstETH
      );
      await wstETH.mint(ethers.parseEther("1000"));
    }
    if (networkData.DAI) {
      DAI = await ethers.getContractAt(
        "contracts/WormHole/interfaces/IERC20.sol:IERC20",
        networkData.DAI
      );
    }
    if (networkData.DBT) {
      DBT = await ethers.getContractAt(
        "contracts/WormHole/interfaces/IERC20.sol:IERC20",
        networkData.DBT
      );
      await DBT.allocateTo(deployer.address, ethers.parseEther("100000000"));
    }
  });

  it("can store numbers and read them ", async () => {
    await testFacet.setNumber([3]);
    const num = await testFacet.getNumber();
    console.log(num.toString());
  });
  it("can read counter", async () => {
    let c = await hyperFacet.getCounter();
    console.log(c.toString());
  });
  it("create pool speica", async () => {
    // const amount = ethers.parseEther("1.5");
    // let tx = await WETH.deposit({ value: amount });
    // await tx.wait();
    // //formatEther divides by 10^18
    // console.log(amount.toString());

    // console.log(
    //   "WETH Balance:",
    //   (await WETH.balanceOf(deployer.address)).toString()
    // );
    // //Create swapRouter to interact with
    // const swapAmount = ethers.parseEther(".5");
    // const swapRouter = await ethers.getContractAt(
    //   "IV3SwapRouter",
    //   networkData.SwapRouter
    // );
    // let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
    // tx = await WETH.approve(networkData.SwapRouter, swapAmount.toString());
    // await tx.wait();

    // // let ExactInputSingleParams = {
    // //   tokenIn: WETH.target,
    // //   tokenOut: USDC.target,
    // //   fee: "3000",
    // //   recipient: deployer.address,
    // //   deadline: timeStamp + 10000, //Timestamp is in seconds
    // //   amountIn: swapAmount,
    // //   amountOutMinimum: 0,
    // //   sqrtPriceLimitX96: 0,
    // // };
    // console.log(WETH.target, USDC.target);
    // let fee = "3000";
    // if (networkData.Network == "goerli") {
    //   fee = "500";
    // }
    // if (networkData.Network == "arbogerli") {
    //   fee = "10000";
    // }
    // let ExactInputSingleParams = {
    //   tokenIn: WETH.target,
    //   tokenOut: USDC.target,
    //   fee: fee,
    //   recipient: deployer.address,
    //   amountIn: swapAmount,
    //   amountOutMinimum: 0,
    //   sqrtPriceLimitX96: 0,
    // };
    // tx = await swapRouter.exactInputSingle(ExactInputSingleParams);
    // await tx.wait();

    // console.log(
    //   "USDC Balance:",
    //   (await USDC.balanceOf(deployer.address)).toString()
    // );
    // console.log(networkData);
    // console.log(networkData.DAI);
    // if (networkData.DAI) {
    //   let decimalAdj = Decimal.pow(10, 6);
    //   let usdcAmount = new Decimal(700).times(decimalAdj);
    //   await USDC.approve(networkData.SwapRouter, usdcAmount.toString());

    //   ExactInputSingleParams.tokenOut = DAI.target;
    //   ExactInputSingleParams.tokenIn = USDC.target;
    //   ExactInputSingleParams.amountIn = usdcAmount.toString();

    //   await swapRouter.exactInputSingle(ExactInputSingleParams);
    //   console.log(
    //     "DAI Balance:",
    //     (await DAI.balanceOf(deployer.address)).toString()
    //   );
    // }
    // //I need to add ETH/USDC liquidty to my v4 pool
    // //First, initailze pool, addys must be sorted
    // let addresses = [WETH.target, USDC.target];
    // addresses.sort();
    // const hook = "0x0000000000000000000000000000000000000000";
    // const poolKey = {
    //   currency0: addresses[0].toString().trim(),
    //   currency1: addresses[1].toString().trim(),
    //   fee: "3000",
    //   tickSpacing: "60",
    //   hooks: hook,
    // };
    // //const sqrtPrice = calculateSqrtPriceX96(price, 6, 18);
    // const currentTick = getNearestUsableTick(
    //   202494, //Tick copied from the V3 Pool

    //   parseInt(poolKey.tickSpacing)
    // );

    // let price = Decimal.pow(1.0001, 202494);
    // let dividor = Decimal.pow(10, 12);
    // let res = price.dividedBy(dividor);

    // res = new Decimal(1).dividedBy(res);
    // console.log(res.toFixed());
    // let sqrtPrice = await uniswapFacet.getSqrtAtTick(currentTick);
    // sqrtPrice = new Decimal(sqrtPrice.toString());
    // // const a = await poolManager.initialize.staticCall(
    // //   poolKey,
    // //   sqrtPrice.toFixed(),
    // //   "0x"
    // // );
    // // console.log(a.toString());
    // console.log("Initialzing pool");
    // tx = await uniswapFacet.initializePool(
    //   addresses[0].toString().trim(),
    //   addresses[1].toString().trim(),
    //   sqrtPrice.toFixed(0),
    //   hookFacet.target,
    //   "0x"
    // );
    // await tx.wait();

    // const lowerTick = currentTick - parseInt(poolKey.tickSpacing) * 30;
    // const upperTick = currentTick + parseInt(poolKey.tickSpacing) * 30;
    // //Since price is basically 1:1
    // //we will just use an even amount
    // const wethDecimals = Decimal.pow(10, 18);
    // const usdcDecimals = Decimal.pow(10, 6);

    // let wethAmount = new Decimal(0.6);

    // usdcAmount = wethAmount.times(res);
    // wethAmount = wethAmount.times(wethDecimals).round();
    // usdcAmount = usdcAmount.times(usdcDecimals).round();
    // tx = await USDC.transfer(diamondAddress, usdcAmount.toFixed());
    // await tx.wait();

    // wethAmount = new Decimal(0.61);
    // wethAmount = wethAmount.times(wethDecimals).round();
    // tx = await WETH.transfer(diamondAddress, wethAmount.toFixed());
    // await tx.wait();
    // console.log("Adding liquidty");
    // tx = await uniswapFacet.addLiquidty(
    //   WETH.target,
    //   USDC.target,
    //   lowerTick,
    //   upperTick,
    //   wethAmount.toFixed(),
    //   usdcAmount.toFixed()
    // );
    // await tx.wait();

    let liq = await uniswapFacet.getPoolLiquidity(USDC.target, WETH.target);
    console.log("Liquidity", liq.toString());
  });
  it("can use test facet with control flow gub", async () => {
    let instructions = [];
    instructions.push(await instructionFacet.instrucSetNumber());
    instructions.push(await instructionFacet.instrucGetSum());
    instructions.push(await instructionFacet.instrucSetNumber());
    instructions.push(await instructionFacet.instrucGetNumber());
    console.log(instructions);
    const packedInstructions =
      await managerFacet.convertBytes5ArrayToBytes(instructions);
    console.log(packedInstructions);
    const instructionsWithInput = await managerFacet.addDataToFront(
      [2],
      packedInstructions
    );
    console.log(instructionsWithInput);
    let tx = await managerFacet.startWorking(instructionsWithInput);
    await tx.wait();
    console.log((await testFacet.getNumber()).toString());
  });
  // it("can get weth and swap j11", async () => {
  //   const amount = ethers.parseEther("100");
  //   //formatEther divides by 10^18
  //   console.log(amount.toString());

  //   await WETH.deposit({ value: amount });
  //   console.log(
  //     "WETH Balance:",
  //     (await WETH.balanceOf(deployer.address)).toString()
  //   );
  //   //Create swapRouter to interact with
  //   const swapAmount = ethers.parseEther("25");
  //   const swapRouter = await ethers.getContractAt(
  //     "IV3SwapRouter",
  //     networkData.SwapRouter
  //   );
  //   let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
  //   await WETH.approve(networkData.SwapRouter, swapAmount.toString());

  //   console.log(WETH.target, USDC.target);
  //   let fee = "3000";
  //   if (networkData.Network == "goerli") {
  //     fee = "500";
  //   }
  //   if (networkData.Network == "arbogerli") {
  //     fee = "10000";
  //   }
  //   let ExactInputSingleParams = {
  //     tokenIn: WETH.target,
  //     tokenOut: USDC.target,
  //     fee: fee,
  //     recipient: deployer.address,
  //     amountIn: swapAmount,
  //     amountOutMinimum: 0,
  //     sqrtPriceLimitX96: 0,
  //   };
  //   await swapRouter.exactInputSingle(ExactInputSingleParams);
  //   console.log(
  //     "USDC Balance:",
  //     (await USDC.balanceOf(deployer.address)).toString()
  //   );
  //   console.log(networkData);
  //   console.log(networkData.DAI);
  //   if (networkData.DAI) {
  //     let decimalAdj = Decimal.pow(10, 6);
  //     const usdcAmount = new Decimal(20000).times(decimalAdj);
  //     await USDC.approve(networkData.SwapRouter, usdcAmount.toString());

  //     ExactInputSingleParams.tokenOut = DAI.target;
  //     ExactInputSingleParams.tokenIn = USDC.target;
  //     ExactInputSingleParams.amountIn = usdcAmount.toString();

  //     await swapRouter.exactInputSingle(ExactInputSingleParams);
  //     console.log(
  //       "DAI Balance:",
  //       (await DAI.balanceOf(deployer.address)).toString()
  //     );
  //   }
  // });
  describe("Protocal Tests dd", function () {
    beforeEach(async () => {
      const amount = ethers.parseEther("100");
      await WETH.deposit({ value: amount });

      //formatEther divides by 10^18
      console.log(amount.toString());

      console.log(
        "WETH Balance:",
        (await WETH.balanceOf(deployer.address)).toString()
      );
      //Create swapRouter to interact with
      const swapAmount = ethers.parseEther("25");
      const swapRouter = await ethers.getContractAt(
        "IV3SwapRouter",
        networkData.SwapRouter
      );
      let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
      await WETH.approve(networkData.SwapRouter, swapAmount.toString());
      // let ExactInputSingleParams = {
      //   tokenIn: WETH.target,
      //   tokenOut: USDC.target,
      //   fee: "3000",
      //   recipient: deployer.address,
      //   deadline: timeStamp + 10000, //Timestamp is in seconds
      //   amountIn: swapAmount,
      //   amountOutMinimum: 0,
      //   sqrtPriceLimitX96: 0,
      // };
      console.log(WETH.target, USDC.target);
      let fee = "3000";
      if (networkData.Network == "goerli") {
        fee = "500";
      }
      if (networkData.Network == "arbogerli") {
        fee = "10000";
      }
      let ExactInputSingleParams = {
        tokenIn: WETH.target,
        tokenOut: USDC.target,
        fee: fee,
        recipient: deployer.address,
        amountIn: swapAmount,
        amountOutMinimum: 0,
        sqrtPriceLimitX96: 0,
      };
      await swapRouter.exactInputSingle(ExactInputSingleParams);
      console.log(
        "USDC Balance:",
        (await USDC.balanceOf(deployer.address)).toString()
      );
      console.log(networkData);
      console.log(networkData.DAI);
      if (networkData.DAI) {
        let decimalAdj = Decimal.pow(10, 6);
        const usdcAmount = new Decimal(20000).times(decimalAdj);
        await USDC.approve(networkData.SwapRouter, usdcAmount.toString());

        ExactInputSingleParams.tokenOut = DAI.target;
        ExactInputSingleParams.tokenIn = USDC.target;
        ExactInputSingleParams.amountIn = usdcAmount.toString();

        await swapRouter.exactInputSingle(ExactInputSingleParams);
        console.log(
          "DAI Balance:",
          (await DAI.balanceOf(deployer.address)).toString()
        );
      }
    });
    describe("UMA Tests", function () {
      //UMA Tests
      it("asserting data g1", async () => {
        if (networkData.DBT) {
          let decimalAdj = Decimal.pow(10, 18);
          const usdcAmount = new Decimal(500).times(decimalAdj);

          let num = ethers.toBeHex(12);

          //Padd our hex with 32 bytes so the total length is 64 digits
          let message = ethers.zeroPadValue(num, 32);
          num = ethers.toBeHex(412);

          //Padd our hex with 32 bytes so the total length is 64 digits
          let dataID = ethers.zeroPadValue(num, 32);
          await DBT.approve(diamondAddress, usdcAmount.toFixed());
          await umaFacet.assertDataFor(dataID, message, deployer.address);
          const assertionID = await umaFacet.getAssertionID(0);

          let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
          await ethers.provider.send("evm_mine", [timeStamp + 65]);
          await umaFacet.settleAndGetAssertionResult(assertionID);
          await umaFacet.settleAndGetAssertionResult(assertionID);
          const res =
            await umaFacet.settleAndGetAssertionResult.staticCall(assertionID);
          console.log(res.toString());
        } else if (networkData.OOV3) {
          let decimalAdj = Decimal.pow(10, 6);
          const usdcAmount = new Decimal(500).times(decimalAdj);

          let num = ethers.toBeHex(12);

          //Padd our hex with 32 bytes so the total length is 64 digits
          let message = ethers.zeroPadValue(num, 32);
          num = ethers.toBeHex(412);

          //Padd our hex with 32 bytes so the total length is 64 digits
          let dataID = ethers.zeroPadValue(num, 32);
          await USDC.approve(diamondAddress, usdcAmount.toFixed());
          await umaFacet.assertDataFor(dataID, message, deployer.address);
          const assertionID = await umaFacet.getAssertionID(0);

          let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
          await ethers.provider.send("evm_mine", [timeStamp + 65]);
          await umaFacet.settleAndGetAssertionResult(assertionID);
          await umaFacet.settleAndGetAssertionResult(assertionID);
          const res =
            await umaFacet.settleAndGetAssertionResult.staticCall(assertionID);
          console.log(res.toString());
        }
      });
    });
    describe("Uniswap Tests", function () {
      it("can add liquidty and initialze a pool 1123", async () => {
        //I need to add ETH/USDC liquidty to my v4 pool
        //First, initailze pool, addys must be sorted
        if (networkData.Network == "basegoerli") {
          const faucet = await ethers.getContractAt(
            "contracts/WormHole/interfaces/IERC20.sol:IERC20",
            "0x54fcbea987d18e027a827ee25e1943cf0874eba8"
          );
          await faucet.drip(USDC.target);
        }
        console.log(
          "USDC Balance:",
          (await USDC.balanceOf(deployer.address)).toString()
        );
        let addresses = [WETH.target, USDC.target];
        addresses.sort();
        const hook = "0x0000000000000000000000000000000000000000";
        const poolKey = {
          currency0: addresses[0].toString().trim(),
          currency1: addresses[1].toString().trim(),
          fee: "3000",
          tickSpacing: "60",
          hooks: hook,
        };
        //const sqrtPrice = calculateSqrtPriceX96(price, 6, 18);
        const currentTick = getNearestUsableTick(
          202494, //Tick copied from the V3 Pool

          parseInt(poolKey.tickSpacing)
        );

        let price = Decimal.pow(1.0001, 202494);
        let dividor = Decimal.pow(10, 12);
        let res = price.dividedBy(dividor);

        res = new Decimal(1).dividedBy(res);
        console.log(res.toFixed());
        let sqrtPrice = await uniswapFacet.getSqrtAtTick(currentTick);
        sqrtPrice = new Decimal(sqrtPrice.toString());
        // const a = await poolManager.initialize.staticCall(
        //   poolKey,
        //   sqrtPrice.toFixed(),
        //   "0x"
        // );
        // console.log(a.toString());
        console.log(addresses[0], addresses[1]);
        console.log("howdy");
        console.log(sqrtPrice.toFixed(0));
        console.log(poolManager.target);
        console.log(hookFacet.target);
        await uniswapFacet.initializePool(
          addresses[0].toString().trim(),
          addresses[1].toString().trim(),
          sqrtPrice.toFixed(0),
          hookFacet.target,
          "0x"
        );
        console.log("howdy");

        const lowerTick = currentTick - parseInt(poolKey.tickSpacing) * 30;
        const upperTick = currentTick + parseInt(poolKey.tickSpacing) * 30;
        //Since price is basically 1:1
        //we will just use an even amount
        const wethDecimals = Decimal.pow(10, 18);
        const usdcDecimals = Decimal.pow(10, 6);

        let wethAmount = new Decimal(0.05);
        console.log("howdy");

        let usdcAmount = wethAmount.times(res);
        wethAmount = wethAmount.times(wethDecimals).round();
        usdcAmount = usdcAmount.times(usdcDecimals).round();

        await USDC.transfer(diamondAddress, usdcAmount.toFixed());
        wethAmount = new Decimal(0.052);
        wethAmount = wethAmount.times(wethDecimals).round();
        await WETH.transfer(diamondAddress, wethAmount.toFixed());

        await uniswapFacet.addLiquidty(
          WETH.target,
          USDC.target,
          lowerTick,
          upperTick,
          wethAmount.toFixed(),
          usdcAmount.toFixed()
        );
        let liq = await uniswapFacet.getPoolLiquidity(USDC.target, WETH.target);
        console.log("Liquidity 1", liq.toString());
        const swapAmount = ethers.parseEther("1");
        console.log(swapAmount.toString());

        console.log(
          "Balance Before",
          (await USDC.balanceOf(deployer.address)).toString()
        );
        await WETH.transfer(diamondAddress, swapAmount.toString());

        await uniswapFacet.swap(
          WETH.target,
          USDC.target,
          swapAmount.toString()
        );
        console.log(
          "Balance After",
          (await USDC.balanceOf(deployer.address)).toString()
        );

        await uniswapFacet.closePosition(
          USDC.target,
          WETH.target,
          lowerTick,
          upperTick
        );

        liq = await uniswapFacet.getPoolLiquidity(USDC.target, WETH.target);
        console.log("Liquidity", liq.toString());

        const awesomeCounter = await hookFacet.getLeAwesomeCounter();
        console.log(awesomeCounter.toString());
      });
    });
    describe("Compound Tests", function () {
      it("can supply and borrow on COMP ", async () => {
        console.log("Starting");

        let decimalAdj = Decimal.pow(10, 18);
        const wethAmount = new Decimal(2).times(decimalAdj);
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        console.log("WETH Amount", wethAmount.toFixed());
        await leverageFacet.supply(WETH.target, wethAmount.toFixed());
        const bal = await leverageFacet.getCollateralBalance(WETH.target);
        console.log(bal.toString());
        const info = await leverageFacet.getAssetInfo(WETH.target);
        console.log(info.toString());
        let rate = await leverageFacet.getSupplyRate();
        console.log(
          "Supply Rate",
          (parseInt(rate.toString()) / 10 ** 18) * 86400 * 365
        );
        rate = await leverageFacet.getBorrowRate();
        console.log(
          "Interest Rate",
          (parseInt(rate.toString()) / 10 ** 18) * 86400 * 365
        );
        decimalAdj = Decimal.pow(10, 6);
        const usdcAmount = new Decimal(1000).times(decimalAdj);
        //Le Price is 1608.03000000
        console.log(usdcAmount.toFixed());

        console.log((await USDC.balanceOf(diamondAddress)).toString());

        await leverageFacet.withdraw(USDC.target, usdcAmount.toFixed());

        console.log((await USDC.balanceOf(diamondAddress)).toString());
      });
    });
    describe("COMP/Uniswap", function () {
      beforeEach(async () => {
        //I need to add ETH/USDC liquidty to my v4 pool
        //First, initailze pool, addys must be sorted
        let addresses = [WETH.target, USDC.target];
        addresses.sort();
        const hook = "0x0000000000000000000000000000000000000000";
        const poolKey = {
          currency0: addresses[0].toString().trim(),
          currency1: addresses[1].toString().trim(),
          fee: "3000",
          tickSpacing: "60",
          hooks: hook,
        };
        //const sqrtPrice = calculateSqrtPriceX96(price, 6, 18);
        const currentTick = getNearestUsableTick(
          202494, //Tick copied from the V3 Pool

          parseInt(poolKey.tickSpacing)
        );

        let price = Decimal.pow(1.0001, 202494);
        let dividor = Decimal.pow(10, 12);
        let res = price.dividedBy(dividor);

        res = new Decimal(1).dividedBy(res);
        console.log(res.toFixed());
        let sqrtPrice = await uniswapFacet.getSqrtAtTick(currentTick);
        sqrtPrice = new Decimal(sqrtPrice.toString());
        // const a = await poolManager.initialize.staticCall(
        //   poolKey,
        //   sqrtPrice.toFixed(),
        //   "0x"
        // );
        // console.log(a.toString());

        await uniswapFacet.initializePool(
          addresses[0].toString().trim(),
          addresses[1].toString().trim(),
          sqrtPrice.toFixed(0),
          hookFacet.target,
          "0x"
        );

        const lowerTick = currentTick - parseInt(poolKey.tickSpacing) * 30;
        const upperTick = currentTick + parseInt(poolKey.tickSpacing) * 30;
        //Since price is basically 1:1
        //we will just use an even amount
        const wethDecimals = Decimal.pow(10, 18);
        const usdcDecimals = Decimal.pow(10, 6);

        let wethAmount = new Decimal(19.5);

        let usdcAmount = wethAmount.times(res);
        wethAmount = wethAmount.times(wethDecimals).round();
        usdcAmount = usdcAmount.times(usdcDecimals).round();
        await USDC.transfer(diamondAddress, usdcAmount.toFixed());
        wethAmount = new Decimal(19.52);
        wethAmount = wethAmount.times(wethDecimals).round();
        await WETH.transfer(diamondAddress, wethAmount.toFixed());

        await uniswapFacet.addLiquidty(
          WETH.target,
          USDC.target,
          lowerTick,
          upperTick,
          wethAmount.toFixed(),
          usdcAmount.toFixed()
        );
        let liq = await uniswapFacet.getPoolLiquidity(USDC.target, WETH.target);
        console.log("Liquidity", liq.toString());
      });
      it("can leverage up ", async () => {
        console.log("-----------------------------------");
        console.log("  Oh yeah, its leverage time\n");
        let decimalAdj = Decimal.pow(10, 18);
        //Minmum is 100
        const wethAmount = new Decimal(0.1).times(decimalAdj);
        decimalAdj = Decimal.pow(10, 18);
        const swapAmount = new Decimal(0.2).times(decimalAdj);
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        const args = [
          (await managerFacet.convertAddyToNum(WETH.target)).toString(),
          (await managerFacet.convertAddyToNum(USDC.target)).toString(),
          wethAmount.toFixed(),
          swapAmount.toFixed(),
        ];
        await leverageFacet.leverageUp(args);
        let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        await ethers.provider.send("evm_mine", [timeStamp + 86400 * 20]);
        const profitLoss = await leverageFacet.returnProfit.staticCall([0]);
        console.log("Profit", profitLoss.toString());
        // console.log((await Comet.borrowBalanceOf(diamondAddress)).toString());

        // console.log((await WETH.balanceOf(diamondAddress)).toString());

        await leverageFacet.closePosition([0]);
        //await leverageFacet.withdraw(WETH.target, "97587014333073605");
        // console.log((await WETH.balanceOf(diamondAddress)).toString());
        //messsing around with the interst

        // let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        // await ethers.provider.send("evm_mine", [timeStamp + 86400 * 365]);
      });
    });
    describe("Spark Tests", function () {
      it("can supply and borrow on Spark  ", async () => {
        if (networkData.SparkLend) {
          console.log("Starting");
          await wstETH.mint(ethers.parseEther("1000"));
          let decimalAdj = Decimal.pow(10, 18);
          const wethAmount = new Decimal(1).times(decimalAdj);
          console.log(await wstETH.balanceOf(deployer.address));
          await wstETH.transfer(diamondAddress, wethAmount.toFixed());
          let args = [
            (await managerFacet.convertAddyToNum(wstETH.target)).toString(),
            wethAmount.toFixed(),
          ];
          await sparkFacet.supplySpark(args);
          const daiAmount = new Decimal(10).times(decimalAdj);
          args = [
            (await managerFacet.convertAddyToNum(DAI.target)).toString(),
            daiAmount.toFixed(),
          ];
          await sparkFacet.borrowSpark(args);
        }
      });
    });
    describe("Spark/Uniswap", function () {
      beforeEach(async () => {
        if (networkData.SparkLend) {
          //I need to add ETH/USDC liquidty to my v4 pool
          //First, initailze pool, addys must be sorted
          let addresses = [wstETH.target, DAI.target];
          addresses.sort();
          const hook = "0x0000000000000000000000000000000000000000";
          const poolKey = {
            currency0: addresses[0].toString().trim(),
            currency1: addresses[1].toString().trim(),
            fee: "3000",
            tickSpacing: "60",
            hooks: hook,
          };
          //const sqrtPrice = calculateSqrtPriceX96(price, 6, 18);
          const currentTick = getNearestUsableTick(
            -73799, //Tick copied from the V3 Pool

            parseInt(poolKey.tickSpacing)
          );

          let price = Decimal.pow(1.0001, -73799);
          let res = price;
          res = new Decimal(1).dividedBy(res);
          console.log(res.toFixed());
          let sqrtPrice = await uniswapFacet.getSqrtAtTick(currentTick);
          sqrtPrice = new Decimal(sqrtPrice.toString());
          // const a = await poolManager.initialize.staticCall(
          //   poolKey,
          //   sqrtPrice.toFixed(),
          //   "0x"
          // );
          // console.log(a.toString());

          await uniswapFacet.initializePool(
            addresses[0].toString().trim(),
            addresses[1].toString().trim(),
            sqrtPrice.toFixed(0),
            hookFacet.target,
            "0x"
          );

          const lowerTick = currentTick - parseInt(poolKey.tickSpacing) * 30;
          const upperTick = currentTick + parseInt(poolKey.tickSpacing) * 30;
          //Since price is basically 1:1
          //we will just use an even amount
          const wstETHDecimals = Decimal.pow(10, 18);

          let wstETHAmount = new Decimal(3);

          let daiAmount = wstETHAmount.times(res);
          wstETHAmount = wstETHAmount.times(wstETHDecimals).round();
          daiAmount = daiAmount.times(wstETHDecimals).round();
          await DAI.transfer(diamondAddress, daiAmount.toFixed());
          wstETHAmount = new Decimal(3.02);
          wstETHAmount = wstETHAmount.times(wstETHDecimals).round();
          await wstETH.transfer(diamondAddress, wstETHAmount.toFixed());

          await uniswapFacet.addLiquidty(
            wstETH.target,
            DAI.target,
            lowerTick,
            upperTick,
            wstETHAmount.toFixed(),
            daiAmount.toFixed()
          );
          let liq = await uniswapFacet.getPoolLiquidity(
            DAI.target,
            wstETH.target
          );
          console.log("Liquidity", liq.toString());
        }
      });
      it("can leverage up g1e", async () => {
        if (networkData.SparkLend) {
          console.log("-----------------------------------");
          console.log("  Oh yeah, its leverage time\n");
          let decimalAdj = Decimal.pow(10, 18);
          //Minmum is 100
          const wethAmount = new Decimal(0.1).times(decimalAdj);
          decimalAdj = Decimal.pow(10, 18);
          const swapAmount = new Decimal(0.1).times(decimalAdj);
          await wstETH.transfer(diamondAddress, wethAmount.toFixed());
          const args = [
            (await managerFacet.convertAddyToNum(wstETH.target)).toString(),
            (await managerFacet.convertAddyToNum(DAI.target)).toString(),
            wethAmount.toFixed(),
            swapAmount.toFixed(),
          ];
          await wstETH.transfer(diamondAddress, wethAmount.toFixed());

          await sparkFacet.leverageUpSpark(args);
          let info = await sparkFacet.getUserAccountData(diamondAddress);
          console.log(info.toString());
          console.log("here!!");
          await sparkFacet.closePositionSpark([0]);
          info = await sparkFacet.getUserAccountData(diamondAddress);
          console.log(info.toString());
          // console.log((await Comet.borrowBalanceOf(diamondAddress)).toString());

          // console.log((await WETH.balanceOf(diamondAddress)).toString());

          // await sparkFacet.closePositionSpark(DAI.target, WETH.target, 0);
          // info = await sparkFacet.getUserAccountData(diamondAddress);
          // console.log(info.toString());
          //await leverageFacet.withdraw(WETH.target, "97587014333073605");
          // console.log((await WETH.balanceOf(diamondAddress)).toString());
          //messsing around with the interst

          // let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
          // await ethers.provider.send("evm_mine", [timeStamp + 86400 * 365]);
        }
      });
    });
    describe("attempting control flow ", function () {
      beforeEach(async () => {
        //I need to add ETH/USDC liquidty to my v4 pool
        //First, initailze pool, addys must be sorted
        let addresses = [WETH.target, USDC.target];
        addresses.sort();
        const hook = "0x0000000000000000000000000000000000000000";
        const poolKey = {
          currency0: addresses[0].toString().trim(),
          currency1: addresses[1].toString().trim(),
          fee: "3000",
          tickSpacing: "60",
          hooks: hook,
        };
        //const sqrtPrice = calculateSqrtPriceX96(price, 6, 18);
        const currentTick = getNearestUsableTick(
          202494, //Tick copied from the V3 Pool

          parseInt(poolKey.tickSpacing)
        );

        let price = Decimal.pow(1.0001, 202494);
        let dividor = Decimal.pow(10, 12);
        let res = price.dividedBy(dividor);

        res = new Decimal(1).dividedBy(res);
        console.log(res.toFixed());
        let sqrtPrice = await uniswapFacet.getSqrtAtTick(currentTick);
        sqrtPrice = new Decimal(sqrtPrice.toString());
        // const a = await poolManager.initialize.staticCall(
        //   poolKey,
        //   sqrtPrice.toFixed(),
        //   "0x"
        // );
        // console.log(a.toString());

        await uniswapFacet.initializePool(
          addresses[0].toString().trim(),
          addresses[1].toString().trim(),
          sqrtPrice.toFixed(0),
          hookFacet.target,
          "0x"
        );

        const lowerTick = currentTick - parseInt(poolKey.tickSpacing) * 30;
        const upperTick = currentTick + parseInt(poolKey.tickSpacing) * 30;
        //Since price is basically 1:1
        //we will just use an even amount
        const wethDecimals = Decimal.pow(10, 18);
        const usdcDecimals = Decimal.pow(10, 6);

        let wethAmount = new Decimal(19.5);

        let usdcAmount = wethAmount.times(res);
        wethAmount = wethAmount.times(wethDecimals).round();
        usdcAmount = usdcAmount.times(usdcDecimals).round();
        await USDC.transfer(diamondAddress, usdcAmount.toFixed());
        wethAmount = new Decimal(19.52);
        wethAmount = wethAmount.times(wethDecimals).round();
        await WETH.transfer(diamondAddress, wethAmount.toFixed());

        await uniswapFacet.addLiquidty(
          WETH.target,
          USDC.target,
          lowerTick,
          upperTick,
          wethAmount.toFixed(),
          usdcAmount.toFixed()
        );
        let liq = await uniswapFacet.getPoolLiquidity(USDC.target, WETH.target);
        console.log("Liquidity", liq.toString());
      });
      it("can use test facet with control flow  ", async () => {
        let instructions = [];
        instructions.push(await instructionFacet.instrucSetNumber());
        instructions.push(await instructionFacet.instrucGetSum());
        instructions.push(await instructionFacet.instrucSetNumber());
        instructions.push(await instructionFacet.instrucGetNumber());
        console.log(instructions);
        const packedInstructions =
          await managerFacet.convertBytes5ArrayToBytes(instructions);
        console.log(packedInstructions);
        const instructionsWithInput = await managerFacet.addDataToFront(
          [2],
          packedInstructions
        );
        console.log(instructionsWithInput);
        await managerFacet.startWorking(instructionsWithInput);
        console.log((await testFacet.getNumber()).toString());
      });
      it("can leverage up ", async () => {
        let instructions = [];
        instructions.push(await instructionFacet.instrucLeverageUp());
        instructions.push(await instructionFacet.instrucReturnProfit());
        console.log(instructions);
        const packedInstructions =
          await managerFacet.convertBytes5ArrayToBytes(instructions);
        console.log(packedInstructions);
        const wethNumber = managerFacet.convertAddyToNum(WETH.target);
        const usdcNumber = managerFacet.convertAddyToNum(USDC.target);
        let decimalAdj = Decimal.pow(10, 18);
        //Minmum is 100
        const wethAmount = new Decimal(0.1).times(decimalAdj);
        decimalAdj = Decimal.pow(10, 18);
        const swapAmount = new Decimal(0.2).times(decimalAdj);

        const instructionsWithInput = await managerFacet.addDataToFront(
          [wethNumber, usdcNumber, wethAmount.toFixed(), swapAmount.toFixed()],
          packedInstructions
        );
        console.log(instructionsWithInput);
        //REMEBER TO TRANSFER THE COLLATERAL IN ⚠⚠⚠⚠⚠🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨🚨
        //ALSO REMBER THAT ALL INPUTS NEED TO BE AN ARRAY OF ONLY UINT256
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        const res = await managerFacet.parseLastResultAndExecute.staticCall(
          instructionsWithInput,
          1
        );
        // const res = await managerFacet.parseLastResultAndExecute.staticCall(
        //   instructionsWithInput,
        //   1
        // );
        console.log(res.toString());
      });
      it("can attach controlFlow to hooks", async () => {
        let instructions = [];
        instructions.push(await instructionFacet.instrucGetNumber());
        console.log(instructions);
        const packedInstructions =
          await managerFacet.convertBytes5ArrayToBytes(instructions);
        console.log(packedInstructions);

        const instructionsWithInput = await managerFacet.addDataToFront(
          [0],
          packedInstructions
        );
        //console.log(instructionsWithInput);

        await managerFacet.startWorking(instructionsWithInput);
        await managerFacet.createNewHookFlow(
          "Gets a number",
          instructionsWithInput
        );
        const swapAmount = ethers.parseEther("1");
        console.log(swapAmount.toString());

        await WETH.transfer(diamondAddress, swapAmount.toString());

        await uniswapFacet.swap(
          WETH.target,
          USDC.target,
          swapAmount.toString()
        );
      });
      it("can attach advanced controlFlow to hooks ", async () => {
        let decimalAdj = Decimal.pow(10, 18);
        //Minmum is 100
        const wethAmount = new Decimal(0.1).times(decimalAdj);
        decimalAdj = Decimal.pow(10, 18);
        let swapAmount = new Decimal(0.2).times(decimalAdj);
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        const args = [
          (await managerFacet.convertAddyToNum(WETH.target)).toString(),
          (await managerFacet.convertAddyToNum(USDC.target)).toString(),
          wethAmount.toFixed(),
          swapAmount.toFixed(),
        ];
        await leverageFacet.leverageUp(args);
        let instructions = [];
        instructions.push(await instructionFacet.instrucIsLiquidatable());
        instructions.push(
          await instructionFacet.instrucIfTrueContinueWResult()
        );
        instructions.push(await instructionFacet.instrucClosePosition());
        //instructions.push(await instructionFacet.instrucStop());

        console.log(instructions);
        const packedInstructions =
          await managerFacet.convertBytes5ArrayToBytes(instructions);
        console.log(packedInstructions);

        const instructionsWithInput = await managerFacet.addDataToFront(
          [(await managerFacet.convertAddyToNum(diamondAddress)).toString()],
          packedInstructions
        );
        //console.log(instructionsWithInput);
        console.log("Howdy");

        await managerFacet.startWorking(instructionsWithInput);
        console.log("Howdy");
        console.log((await Comet.borrowBalanceOf(diamondAddress)).toString());

        let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        await ethers.provider.send("evm_mine", [timeStamp + 86400 * 365 * 2]);
        await Comet.accrueAccount(diamondAddress);

        await managerFacet.createNewHookFlow(
          "Gets a number",
          instructionsWithInput
        );
        swapAmount = ethers.parseEther("1");
        console.log(swapAmount.toString());

        await WETH.transfer(diamondAddress, swapAmount.toString());

        await uniswapFacet.swap(
          WETH.target,
          USDC.target,
          swapAmount.toString()
        );
        console.log((await Comet.borrowBalanceOf(diamondAddress)).toString());
      });
      it("position manager ", async () => {
        let instructions = [];
        instructions.push(await instructionFacet.instrucReturnBounds());
        instructions.push(
          await instructionFacet.instrucContinueIfOutOfBounds()
        );
        instructions.push(await instructionFacet.instrucAdjustBounds());
        //instructions.push(await instructionFacet.instrucStop());

        console.log(instructions);
        const packedInstructions =
          await managerFacet.convertBytes5ArrayToBytes(instructions);
        console.log(packedInstructions);

        const instructionsWithInput = await managerFacet.addDataToFront(
          [0],
          packedInstructions
        );
        console.log(instructionsWithInput);
        await managerFacet.createNewHookFlow(
          "Adjust LP",
          instructionsWithInput
        );

        const currentTick = getNearestUsableTick(
          202494, //Tick copied from the V3 Pool

          parseInt(60)
        );

        let price = Decimal.pow(1.0001, 202494);
        let dividor = Decimal.pow(10, 12);
        let res = price.dividedBy(dividor);

        res = new Decimal(1).dividedBy(res);
        console.log(res.toFixed());
        let sqrtPrice = await uniswapFacet.getSqrtAtTick(currentTick);
        sqrtPrice = new Decimal(sqrtPrice.toString());
        // const a = await poolManager.initialize.staticCall(
        //   poolKey,
        //   sqrtPrice.toFixed(),
        //   "0x"
        // );
        // console.log(a.toString());

        const lowerTick = currentTick - parseInt(60) * 60;
        const upperTick = currentTick + parseInt(60) * 60;
        //Since price is basically 1:1
        //we will just use an even amount
        const wethDecimals = Decimal.pow(10, 18);
        const usdcDecimals = Decimal.pow(10, 6);

        let wethAmount = new Decimal(10.5);

        let usdcAmount = wethAmount.times(res);
        wethAmount = wethAmount.times(wethDecimals).round();
        usdcAmount = usdcAmount.times(usdcDecimals).round();
        await USDC.transfer(diamondAddress, usdcAmount.toFixed());
        wethAmount = new Decimal(10.52);
        wethAmount = wethAmount.times(wethDecimals).round();
        await WETH.transfer(diamondAddress, wethAmount.toFixed());

        await uniswapFacet.addLiquidty(
          WETH.target,
          USDC.target,
          lowerTick,
          upperTick,
          wethAmount.toFixed(),
          usdcAmount.toFixed()
        );

        let swapAmount = ethers.parseEther("3");
        console.log(swapAmount.toString());

        await WETH.transfer(diamondAddress, swapAmount.toString());
        const boundsStart = await uniswapFacet.returnBounds();
        console.log("start", boundsStart.toString());
        await uniswapFacet.swap(
          WETH.target,
          USDC.target,
          swapAmount.toString()
        );

        const boundsEnd = await uniswapFacet.returnBounds();
        console.log(boundsEnd.toString());
      });
    });
  });
});
