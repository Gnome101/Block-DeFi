// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "comet/contracts/CometMainInterface.sol";

// Example library to show a simple example of diamond storage

library LeverageLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.leverage.storage");

    struct LeverageState {
        CometMainInterface comet;
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
}

contract LeverageFacet {}
