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

library SparkLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.spark.storage");

    struct SparkState {
        IPool pool;
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
    function supplySpark(address asset, uint256 amount) internal {
        SparkState storage sparkState = diamondStorage();
        sparkState.pool.supply(asset, amount, address(this), 0);
    }

    //Borrow DAI
    function borrow(address asset, uint256 amount) internal {
        SparkState storage sparkState = diamondStorage();
        sparkState.pool.borrow(asset, amount, 1, 0, address(this));
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
}

contract SparkFacet {
    function setPool(address poolAddy) external {
        SparkLib.setPool(poolAddy);
    }

    //Supply WETH
    function supplySpark(address asset, uint256 amount) external {
        SparkLib.supplySpark(asset, amount);
    }

    //Borrow DAI
    function borrow(address asset, uint256 amount) external {
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
        SparkLib.getUserAccountData(user);
    }
}
