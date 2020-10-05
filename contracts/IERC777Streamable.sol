// SPDX-License-Identifier: MIT
pragma experimental ABIEncoderV2;
pragma solidity ^0.6.0;

/**
 * @dev Interface of the ERC20 standard as defined in the EIP.
 */
interface IERC777Streamable {
    // Stream structure
    struct Stream {
        uint256 streamId;
        address creator;
        uint256 startTime;
        uint256 endTime;
        uint256 amount;
    }

    function netBalanceOf(address tokenHolder) external view returns (uint256 netBalance);
    function onHoldOf(address tokenHolder) external view returns (uint256 onHoldBalance);

    function stream(address recipient, uint256 amount, bytes memory data, uint256 startTime, uint256 endTime) external returns (bool);
    function terminate(uint256 streamId) external returns (bool);
}
