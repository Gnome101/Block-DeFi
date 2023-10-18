// SPDX-License-Identifier: MIT OR Apache-2.0
pragma solidity >=0.6.11;
import "./IInterchainSecurityModule.sol";

contract EmptyIsm is IInterchainSecurityModule {
    //https://docs.uma.xyz/developers/quick-start
    /**
     * @notice Returns an enum that represents the type of security model
     * encoded by this ISM.
     * @dev Relayers infer how to fetch and format metadata.
     */
    function moduleType() external view returns (uint8) {
        return 6;
    }

    function verify(
        bytes calldata _metadata,
        bytes calldata _message
    ) external returns (bool) {
        return true;
    }
}
