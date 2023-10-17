// SPDX-License-Identifier: MIT
pragma solidity >=0.8.19;
import {IPoolManager} from "@uniswap/v4-core/contracts/interfaces/IPoolManager.sol";
import "hardhat/console.sol";
import "../Diamond.sol";

contract UniswapHooksFactory {
    address[] public hooks;

    function deploy(
        IDiamondCut.FacetCut[] memory _diamondCut,
        DiamondArgs memory _args,
        bytes32 salt
    ) external {
        console.log("deploying hooks...");
        hooks.push(address(new Diamond{salt: salt}(_diamondCut, _args)));
    }

    function getPrecomputedHookAddress(
        IDiamondCut.FacetCut[] memory _diamondCut,
        DiamondArgs memory _args,
        bytes32 salt
    ) external view returns (address) {
        //Creation code + constructor argument
        bytes32 bytecodeHash = keccak256(
            abi.encodePacked(
                type(Diamond).creationCode,
                abi.encode(_diamondCut, _args)
            )
        );
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff), address(this), salt, bytecodeHash)
        );
        return address(uint160(uint256(hash)));
    }
}
