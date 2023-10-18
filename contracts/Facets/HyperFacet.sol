// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Hyperlane/IMailbox.sol";

library HyperLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.hyperlane.storage");

    struct HyperState {
        address mailBox;
        address localIGP;
        address ism;
        mapping(uint256 => address) domainToAddress;
        uint256 counter;
    }

    function diamondStorage() internal pure returns (HyperState storage ds) {
        bytes32 position = DIAMOND_STORAGE_POSITION;
        assembly {
            ds.slot := position
        }
    }

    function setDomainToAddress(
        uint256 domainID,
        address recipentAddy
    ) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.domainToAddress[domainID] = recipentAddy;
    }

    function getRecipient(uint256 domainID) internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.domainToAddress[domainID];
    }

    function increaseCounter() internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.counter = hyperState.counter + 1;
    }

    function getCounter() internal view returns (uint256) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.counter;
    }

    function poke(uint32 targetDomain) internal {
        HyperState storage hyperState = diamondStorage();
        IMailbox MailBox = IMailbox(hyperState.mailBox);
    }

    function interchainSecurityModule() external view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.ism;
    }

    function setMailBox(address maiLBox) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.mailBox = maiLBox;
    }

    function setGasMaster(address localIGP) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.ism = localIGP;
    }

    function setISM(address ism) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.ism = ism;
    }
}

contract HyperFacet {
    function handle() external {
        HyperLib.increaseCounter();
    }
}
