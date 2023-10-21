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
    function supply(address asset, uint256 amount) internal {
        SparkState storage sparkState = diamondStorage();
        IERC20(asset).approve(address(sparkState.pool), amount);
        sparkState.pool.supply(asset, amount, address(this), 0);
    }

    //Borrow DAI
    function borrow(address asset, uint256 amount) internal {
        SparkState storage sparkState = diamondStorage();
        sparkState.pool.borrow(asset, amount, 2, 0, address(this));
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
        address collateral, //WETH
        address providedToken, //DAI
        uint256 userAmount,
        uint256 swapAmount
    ) internal {
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
            leverageInfo.collateral,
            leverageInfo.swapAmount + leverageInfo.userAmount
        );
        borrow(leverageInfo.providedToken, amountNeededToBorrow);

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

    function closePosition(
        address providedToken, //USDC
        address collateral, //WETH
        uint256 counter
    ) internal {
        SparkState storage sparkState = diamondStorage();
        UniswapLib.UniswapState storage uniswapState = UniswapLib
            .diamondStorage();

        uint256 collateralBalanceBefore = IERC20(providedToken).balanceOf(
            address(uniswapState.poolManager)
        );
        (uint256 amountOwed, , , , , ) = getUserAccountData(address(this));
        UniswapLib.FlashLeverage memory leverageInfo = UniswapLib
            .FlashLeverage({
                collateral: collateral,
                providedToken: providedToken,
                userAmount: 0,
                swapAmount: amountOwed
            });
        //Swap has been called
        bytes memory data = UniswapLib.flashSwapTokens(
            providedToken,
            collateral,
            -int256(amountOwed),
            ActionType.SparkLeverage,
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

        console.log("WITHDRAW!!");
    }
}

contract SparkFacet {
    function setPool(address poolAddy) external {
        SparkLib.setPool(poolAddy);
    }

    //Supply WETH
    function supplySpark(address asset, uint256 amount) external {
        SparkLib.supply(asset, amount);
    }

    //Borrow DAI
    function borrowSpark(address asset, uint256 amount) external {
        SparkLib.borrow(asset, amount);
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
        address collateral, //WETH
        address providedToken, //DAI
        uint256 userAmount,
        uint256 swapAmount
    ) external {
        SparkLib.leverageUpSpark(
            collateral,
            providedToken,
            userAmount,
            swapAmount
        );
    }

    function closePositionSpark(
        address providedToken, //USDC
        address collateral, //WETH
        uint256 counter
    ) external {
        SparkLib.closePosition(providedToken, collateral, counter);
    }
}
