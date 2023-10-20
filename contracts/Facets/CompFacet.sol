// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "comet/contracts/CometMainInterface.sol";
import {IPoolManager, BalanceDelta} from "@uniswap/v4-core/contracts/PoolManager.sol";
import {Currency, CurrencyLibrary} from "@uniswap/v4-core/contracts/types/Currency.sol";
import {PoolKey, PoolId} from "@uniswap/v4-core/contracts/types/PoolId.sol";
import "hardhat/console.sol";

library LeverageLib {
    using CurrencyLibrary for Currency;
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.leverage.storage");

    struct LeverageState {
        CometMainInterface comet;
        IPoolManager poolManager;
    }

    function diamondStorage() internal pure returns (LeverageState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setComet(address cometAddy) internal {
        LeverageState storage leverageState = diamondStorage();
        leverageState.comet = CometMainInterface(cometAddy);
    }

    function leverageUp() internal {
        LeverageState storage leverageState = diamondStorage();
        CometMainInterface comet = leverageState.comet;
        //First we need to call swap on v4 pool
        //Then we need to call supply with the amount we recieved
        //Then we need to call withdraw to take the new tokens out
        //Then we use the tokens withdrawn to pay off the v4 swap
    }

    function supply(address asset, uint256 amount) internal {
        LeverageState storage leverageState = diamondStorage();
        leverageState.comet.supply(asset, amount);
    }
}

contract LeverageFacet {
    function leverageUp() external {
        LeverageLib.leverageUp();
    }

    function supply(address asset, uint256 amount) external {
        LeverageLib.supply(asset, amount);
    }
}
