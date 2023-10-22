// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import "hardhat/console.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20Metadata} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "aave/contracts/interfaces/IPool.sol";
import "./UniswapFacet.sol";
import "./LeverageFacet.sol";
import "./ManagerFacet.sol";

library SparkLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.spark.storage");

    struct SparkState {
        IPool pool;
        mapping(uint256 => levPos) compPositons;
        uint256 posCounter;
        mapping(address => uint256[]) userPositions;
    }

    function diamondStorage() internal pure returns (SparkState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setPool(address poolAddy) internal {
        SparkState storage sparkState = diamondStorage();
        sparkState.pool = IPool(poolAddy);
    }

    //Supply WETH
    function supply(uint256 num1, uint256 num2) internal returns (uint256) {
        SparkState storage sparkState = diamondStorage();
        address asset = ManagerLib.convertNumToAddy(num1);
        uint256 amount = num2;
        IERC20(asset).approve(address(sparkState.pool), amount);
        console.log("huh");
        console.log(address(sparkState.pool));
        sparkState.pool.supply(asset, amount, address(this), 0);
        return amount;
    }

    //Borrow DAI
    function borrow(uint256 num1, uint256 num2) internal returns (uint256) {
        SparkState storage sparkState = diamondStorage();
        address asset = ManagerLib.convertNumToAddy(num1);
        uint256 amount = num2;
        sparkState.pool.borrow(asset, amount, 2, 0, address(this));
        return amount;
    }

    function withdraw(uint256 num1, uint256 num2) internal returns (uint256) {
        SparkState storage sparkState = diamondStorage();
        address asset = ManagerLib.convertNumToAddy(num1);
        uint256 amount = num2;
        sparkState.pool.withdraw(asset, amount, address(this));
        return amount;
    }

    function getUserAccountData(
        address user
    )
        internal
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        SparkState storage sparkState = diamondStorage();
        return sparkState.pool.getUserAccountData(user);
    }

    function leverageUpSpark(
        uint256 num1,
        uint256 num2,
        uint256 num3,
        uint256 num4
    ) internal returns (uint256) {
        SparkState storage sparkState = diamondStorage();

        address collateral = ManagerLib.convertNumToAddy(num1);
        address providedToken = ManagerLib.convertNumToAddy(num2);
        uint256 userAmount = num3;
        uint256 swapAmount = num4;
        UniswapLib.FlashLeverage memory leverageInfo = UniswapLib
            .FlashLeverage({
                collateral: collateral,
                providedToken: providedToken,
                userAmount: userAmount,
                swapAmount: swapAmount
            });
        //Swap has been called
        bytes memory data = UniswapLib.flashSwapTokens(
            providedToken,
            collateral,
            -int256(swapAmount),
            ActionType.SparkLeverage,
            leverageInfo
        );
        return sparkState.posCounter - 1;
    }

    function completeLeverage(
        PoolKey memory poolKey,
        uint256 counter,
        address user
    ) internal {
        SparkState storage sparkState = diamondStorage();

        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();
        BalanceDelta delta;

        UniswapLib.FlashLeverage memory leverageInfo = uniswapState.leveragePos[
            counter
        ];

        delta = uniswapState.poolManager.swap(
            poolKey,
            uniswapState.swaps[counter],
            "0x"
        );
        uint128 amountNeededToBorrow;
        if (leverageInfo.providedToken < leverageInfo.collateral) {
            //Provided token is t0
            //We receved collateral
            UniswapLib._settleCurrencyBalance(
                poolKey.currency1,
                delta.amount1()
            );
            amountNeededToBorrow = uint128(delta.amount0());
        } else {
            UniswapLib._settleCurrencyBalance(
                poolKey.currency0,
                delta.amount0()
            );
            amountNeededToBorrow = uint128(delta.amount1());
        }

        supply(
            ManagerLib.convertAddyToNum(leverageInfo.collateral),
            leverageInfo.swapAmount + leverageInfo.userAmount
        );
        borrow(
            ManagerLib.convertAddyToNum(leverageInfo.providedToken),
            amountNeededToBorrow
        );

        sparkState.compPositons[sparkState.posCounter] = levPos({
            userAmount: leverageInfo.userAmount,
            swapAmount: leverageInfo.swapAmount,
            borrowedAmount: amountNeededToBorrow,
            collateral: leverageInfo.collateral,
            providedToken: leverageInfo.providedToken
        });
        sparkState.userPositions[user].push(sparkState.posCounter);
        sparkState.posCounter++;

        UniswapLib._settleCurrencyBalance(
            Currency.wrap(leverageInfo.providedToken),
            int128(amountNeededToBorrow)
        );
        //withdraw(leverageInfo.collateral,)
        //Then we need to call supply with the amount we recieved
        //Then we need to call withdraw to take the new tokens out
        //Then we use the tokens withdrawn to pay off the v4 swap
    }

    function completeLeverageClose(
        PoolKey memory poolKey,
        uint256 counter,
        address user
    ) internal {
        SparkState storage sparkState = diamondStorage();

        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();
        BalanceDelta delta;

        UniswapLib.FlashLeverage memory leverageInfo = uniswapState.leveragePos[
            counter
        ];

        delta = uniswapState.poolManager.swap(
            poolKey,
            uniswapState.swaps[counter],
            "0x"
        );
        uint128 amountNeededToBorrow;
        console.log("huh!!!!!!");
        console.log(
            IERC20(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844).balanceOf(
                address(this)
            )
        );
        if (leverageInfo.providedToken < leverageInfo.collateral) {
            //Provided token is t0
            //We receved collateral
            UniswapLib._settleCurrencyBalance(
                poolKey.currency1,
                delta.amount1()
            );
            amountNeededToBorrow = uint128(delta.amount0());
        } else {
            UniswapLib._settleCurrencyBalance(
                poolKey.currency0,
                delta.amount0()
            );
            amountNeededToBorrow = uint128(delta.amount1());
        }

        console.log(
            IERC20(0x11fE4B6AE13d2a6055C8D9cF65c55bac32B5d844).balanceOf(
                address(this)
            )
        );

        console.log(amountNeededToBorrow);
        repay(
            ManagerLib.convertAddyToNum(leverageInfo.collateral),
            type(uint).max
        );
        console.log(
            IERC20(leverageInfo.providedToken).balanceOf(address(this))
        );

        withdraw(
            ManagerLib.convertAddyToNum(leverageInfo.providedToken),
            type(uint).max
        );
        console.log(
            IERC20(leverageInfo.providedToken).balanceOf(address(this))
        );
        sparkState.compPositons[sparkState.posCounter] = levPos({
            userAmount: leverageInfo.userAmount,
            swapAmount: leverageInfo.swapAmount,
            borrowedAmount: amountNeededToBorrow,
            collateral: leverageInfo.collateral,
            providedToken: leverageInfo.providedToken
        });
        sparkState.userPositions[user].push(sparkState.posCounter);
        sparkState.posCounter++;

        UniswapLib._settleCurrencyBalance(
            Currency.wrap(leverageInfo.providedToken),
            int128(amountNeededToBorrow)
        );
        //withdraw(leverageInfo.collateral,)
        //Then we need to call supply with the amount we recieved
        //Then we need to call withdraw to take the new tokens out
        //Then we use the tokens withdrawn to pay off the v4 swap
    }

    function repay(uint256 num1, uint256 num2) internal {
        address asset = ManagerLib.convertNumToAddy(num1);
        uint256 amount = num2;
        SparkState storage sparkState = diamondStorage();
        IERC20(asset).approve(address(sparkState.pool), amount);
        sparkState.pool.repay(asset, amount, 2, address(this));
    }

    function closePosition(uint256 num1) internal {
        uint256 counter = num1;
        SparkState storage sparkState = diamondStorage();
        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();
        address providedToken = sparkState.compPositons[counter].collateral;
        address collateral = sparkState.compPositons[counter].providedToken;

        uint256 collateralBalanceBefore = IERC20(providedToken).balanceOf(
            address(uniswapState.poolManager)
        );
        (, uint256 amountOwedDai, , , , ) = getUserAccountData(address(this));
        amountOwedDai = amountOwedDai * 10 ** 10 + 10 ** 18;
        UniswapLib.FlashLeverage memory leverageInfo = UniswapLib
            .FlashLeverage({
                collateral: collateral,
                providedToken: providedToken,
                userAmount: 0,
                swapAmount: amountOwedDai
            });
        //Swap has been called
        bytes memory data = UniswapLib.flashSwapTokens(
            providedToken,
            collateral,
            -int256(amountOwedDai),
            ActionType.SparkLeverageClose,
            leverageInfo
        );

        uint256 collateralBalanceAfter = IERC20(providedToken).balanceOf(
            address(uniswapState.poolManager)
        );
        console.log(
            sparkState.compPositons[counter].swapAmount,
            collateralBalanceAfter,
            collateralBalanceBefore
        );
    }

    function getHF() internal view returns (uint256) {
        SparkState storage sparkState = diamondStorage();
        (, , , , , uint256 HF) = sparkState.pool.getUserAccountData(
            (address(this))
        );
        return HF;
    }
}

contract SparkFacet {
    function setPool(address poolAddy) external {
        SparkLib.setPool(poolAddy);
    }

    //Supply WETH
    function supplySpark(uint256[] memory inputs) external returns (uint256) {
        return SparkLib.supply(inputs[0], inputs[1]);
    }

    //Borrow DAI
    function borrowSpark(uint256[] memory inputs) external returns (uint256) {
        return SparkLib.borrow(inputs[0], inputs[1]);
    }

    function repaySpark(uint256[] memory inputs) external {
        SparkLib.repay(inputs[0], inputs[1]);
    }

    function withdrawSpark(uint256[] memory inputs) external returns (uint256) {
        return SparkLib.withdraw(inputs[0], inputs[1]);
    }

    function getUserAccountData(
        address user
    )
        external
        view
        returns (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        )
    {
        return SparkLib.getUserAccountData(user);
    }

    function leverageUpSpark(
        uint256[] memory inputs
    ) external returns (uint256) {
        return
            SparkLib.leverageUpSpark(
                inputs[0],
                inputs[1],
                inputs[2],
                inputs[3]
            );
    }

    function closePositionSpark(uint256[] memory inputs) external {
        SparkLib.closePosition(inputs[0]);
    }

    function getHF() external returns (uint256) {
        return SparkLib.getHF();
    }
}
