/* global describe it before ethers */
const { ethers } = require("hardhat");
const {
  calculateSqrtPriceX96,
  getNearestUsableTick,
} = require("../utils/uniswapCalculations");
const { assert } = require("chai");
const Decimal = require("decimal.js");
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
  let diamondAddress;
  let deployer;
  let user;
  let poolManager;
  let DAI;
  let WETH;
  let USDC;
  let Comet;
  let CometData;

  beforeEach(async function () {
    accounts = await ethers.getNamedSigners(); // could also do with getNamedAccounts
    deployer = accounts.deployer;
    user = accounts.user;
    await deployments.fixture(["all"]);
    hookFactory = await ethers.getContract("UniswapHooksFactory");
    diamondAddress = await hookFactory.hooks(0);

    //Diamond = await ethers.getContract("Diamond");
    //diamondAddress = Diamond.target;
    poolManager = await ethers.getContract("PoolManager");
    testFacet = await ethers.getContractAt("Test1Facet", diamondAddress);
    hyperFacet = await ethers.getContractAt("HyperFacet", diamondAddress);
    uniswapFacet = await ethers.getContractAt("UniswapFacet", diamondAddress);
    hookFacet = await ethers.getContractAt("HookFacet", diamondAddress);
    managerFacet = await ethers.getContractAt("ManagerFacet", diamondAddress);
    instructionFacet = await ethers.getContractAt(
      "InstructionFacet",
      diamondAddress
    );
    console.log("Pool Manager:", poolManager.target);
    sparkFacet = await ethers.getContractAt("SparkFacet", diamondAddress);
    const sparkPoolAddy = "0xC13e21B648A5Ee794902342038FF3aDAB66BE987";
    await sparkFacet.setPool(sparkPoolAddy);
    await uniswapFacet.setPoolManager(poolManager.target);
    leverageFacet = await ethers.getContractAt("LeverageFacet", diamondAddress);
    const usdcCometAddress = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";
    const usdcCometDataAddy = "0x285617313887d43256F852cAE0Ee4de4b68D45B0";
    await leverageFacet.setComet(usdcCometAddress);
    await leverageFacet.setCometData(usdcCometDataAddy);
    Comet = await ethers.getContractAt("CometMainInterface", usdcCometAddress);
    CometData = await ethers.getContractAt(
      "CometExtInterface",
      usdcCometDataAddy
    );

    const wethAddress = "0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2";
    WETH = await ethers.getContractAt("IWETH9", wethAddress);

    const usdcAddress = "0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48";
    USDC = await ethers.getContractAt("IERC20", usdcAddress);

    const daiAddress = "0x6B175474E89094C44Da98b954EedeAC495271d0F";
    DAI = await ethers.getContractAt("IERC20", daiAddress);
  });

  it("can store numbers and read them ", async () => {
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
  describe("Protocal Tests ", function () {
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
    describe("Uniswap Tests", function () {
      it("can add liquidty and initialze a pool ", async () => {
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

        let wethAmount = new Decimal(19.5);
        console.log("howdy");

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
        const usdcCometAddress = "0xc3d688B66703497DAA19211EEdff47f25384cdc3";

        let decimalAdj = Decimal.pow(10, 18);
        const wethAmount = new Decimal(1).times(decimalAdj);
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
        const usdcAmount = new Decimal(1326).times(decimalAdj);
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
        const swapAmount = new Decimal(0.4).times(decimalAdj);
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        await leverageFacet.leverageUp(
          WETH.target,
          USDC.target,
          wethAmount.toFixed(),
          swapAmount.toFixed()
        );
        let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        await ethers.provider.send("evm_mine", [timeStamp + 86400 * 20]);
        const profitLoss = await leverageFacet.returnProfit.staticCall(0);
        console.log("Profit", profitLoss.toString());
        // console.log((await Comet.borrowBalanceOf(diamondAddress)).toString());

        // console.log((await WETH.balanceOf(diamondAddress)).toString());

        await leverageFacet.closePosition(0);
        //await leverageFacet.withdraw(WETH.target, "97587014333073605");
        // console.log((await WETH.balanceOf(diamondAddress)).toString());
        //messsing around with the interst

        // let timeStamp = (await ethers.provider.getBlock("latest")).timestamp;
        // await ethers.provider.send("evm_mine", [timeStamp + 86400 * 365]);
      });
    });
    describe("Spark Tests", function () {
      it("can supply and borrow on Spark  ", async () => {
        console.log("Starting");
        let decimalAdj = Decimal.pow(10, 18);
        const wethAmount = new Decimal(1).times(decimalAdj);
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        await sparkFacet.supplySpark(WETH.target, wethAmount.toFixed());
        const daiAmount = new Decimal(10).times(decimalAdj);
        await sparkFacet.borrowSpark(DAI.target, daiAmount.toFixed());
      });
    });
    describe("Spark/Uniswap", function () {
      beforeEach(async () => {
        //I need to add ETH/USDC liquidty to my v4 pool
        //First, initailze pool, addys must be sorted
        let addresses = [WETH.target, DAI.target];
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
        const wethDecimals = Decimal.pow(10, 18);

        let wethAmount = new Decimal(19.5);

        let daiAmount = wethAmount.times(res);
        wethAmount = wethAmount.times(wethDecimals).round();
        daiAmount = daiAmount.times(wethDecimals).round();
        await DAI.transfer(diamondAddress, daiAmount.toFixed());
        wethAmount = new Decimal(19.52);
        wethAmount = wethAmount.times(wethDecimals).round();
        await WETH.transfer(diamondAddress, wethAmount.toFixed());

        await uniswapFacet.addLiquidty(
          WETH.target,
          DAI.target,
          lowerTick,
          upperTick,
          wethAmount.toFixed(),
          daiAmount.toFixed()
        );
        let liq = await uniswapFacet.getPoolLiquidity(DAI.target, WETH.target);
        console.log("Liquidity", liq.toString());
      });
      it("can leverage up 512", async () => {
        console.log("-----------------------------------");
        console.log("  Oh yeah, its leverage time\n");
        let decimalAdj = Decimal.pow(10, 18);
        //Minmum is 100
        const wethAmount = new Decimal(0.1).times(decimalAdj);
        decimalAdj = Decimal.pow(10, 18);
        const swapAmount = new Decimal(0.39).times(decimalAdj);
        await WETH.transfer(diamondAddress, wethAmount.toFixed());
        await sparkFacet.leverageUpSpark(
          WETH.target,
          DAI.target,
          wethAmount.toFixed(),
          swapAmount.toFixed()
        );
        let info = await sparkFacet.getUserAccountData(diamondAddress);
        console.log(info.toString());

        await sparkFacet.closePositionSpark(0);
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
      });
    });
    describe("attempting control flow", function () {
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
      it("can use test facet with control flow ", async () => {
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
        const swapAmount = new Decimal(0.4).times(decimalAdj);

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
      it("can attach advanced controlFlow to hooks 31", async () => {
        let decimalAdj = Decimal.pow(10, 18);
        //Minmum is 100
        const wethAmount = new Decimal(0.1).times(decimalAdj);
        decimalAdj = Decimal.pow(10, 18);
        let swapAmount = new Decimal(0.4).times(decimalAdj);
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

        await managerFacet.startWorking(instructionsWithInput);
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
    });
  });
});
