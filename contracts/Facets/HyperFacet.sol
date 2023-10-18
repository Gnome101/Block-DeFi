// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./Hyperlane/IMailbox.sol";
import "./Hyperlane/IInterchainGasPaymaster.sol";
import "hardhat/console.sol";

library HyperLib {
    bytes32 constant DIAMOND_STORAGE_POSITION =
        keccak256("diamond.hyperlane.storage");

    struct HyperState {
        address mailBox;
        address igp;
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

    function hitEmUp(
        uint32 targetDomain,
        uint256 gasAmount,
        uint256 _value
    ) internal {
        HyperState storage hyperState = diamondStorage();
        IMailbox MailBox = IMailbox(hyperState.mailBox);
        IInterchainGasPaymaster IGP = IInterchainGasPaymaster(hyperState.igp);

        address targetAddress = hyperState.domainToAddress[targetDomain];
        bytes32 messageID = MailBox.dispatch(
            targetDomain,
            addressToBytes32(targetAddress),
            abi.encode(msg.sender)
        );

        IGP.payForGas{value: _value}(
            messageID,
            targetDomain,
            gasAmount,
            msg.sender // refunds are returned to the sender
        );
    }

    function addressToBytes32(address _addr) internal pure returns (bytes32) {
        return bytes32(uint256(uint160(_addr)));
    }

    function interchainSecurityModule() internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.ism;
    }

    function setMailBox(address maiLBox) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.mailBox = maiLBox;
    }

    function setGasMaster(address localIGP) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.igp = localIGP;
    }

    function setISM(address ism) internal {
        HyperState storage hyperState = diamondStorage();
        hyperState.ism = ism;
    }

    function getGasMaster() internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.igp;
    }

    function getAddressForDomain(
        uint256 domainID
    ) internal view returns (address) {
        HyperState storage hyperState = diamondStorage();
        return hyperState.domainToAddress[domainID];
    }

    function getQuote(
        uint32 domain,
        uint256 amount
    ) internal view returns (uint256) {
        HyperState storage hyperState = diamondStorage();
        IInterchainGasPaymaster IGP = IInterchainGasPaymaster(hyperState.igp);
        return IGP.quoteGasPayment(domain, amount);
    }
}

contract HyperFacet {
    function handle(
        uint32 _origin,
        bytes32 _sender,
        bytes calldata _body
    ) external {
        HyperLib.increaseCounter();
    }

    function hitEmUp(
        uint32 domain,
        uint256 gasAmount,
        uint256 _value
    ) external payable {
        HyperLib.hitEmUp(domain, gasAmount, _value);
    }

    function interchainSecurityModule() external view returns (address) {
        return HyperLib.interchainSecurityModule();
    }

    function setMailBox(address maiLBox) external {
        HyperLib.setMailBox(maiLBox);
    }

    function setGasMaster(address localIGP) external {
        HyperLib.setGasMaster(localIGP);
    }

    function getGasMaster() external view returns (address) {
        return HyperLib.getGasMaster();
    }

    function setISM(address ism) external {
        HyperLib.setISM(ism);
    }

    function getCounter() external view returns (uint256) {
        return HyperLib.getCounter();
    }

    function setDomainToAddress(
        uint256 domainID,
        address recipentAddy
    ) external {
        HyperLib.setDomainToAddress(domainID, recipentAddy);
    }

    function getAddressForDomain(
        uint256 domainID
    ) external view returns (address) {
        HyperLib.getAddressForDomain(domainID);
    }
}
