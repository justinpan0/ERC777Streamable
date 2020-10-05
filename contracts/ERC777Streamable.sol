// SPDX-License-Identifier: MIT
pragma solidity 0.6.9;

import "@openzeppelin/contracts/token/ERC777/ERC777.sol";

import "./IERC777Streamable.sol";

abstract contract ERC777Streamable is ERC777, IERC777Streamable {
    mapping (address => Stream[]) private _streams;
    mapping (uint256 => address) private _recipients;

    uint256 public _streamId;

    function netBalanceOf(address tokenHolder) public view override returns (uint256 netBalance) {
        uint256 grossBalance = balanceOf(tokenHolder);
        uint256 onHoldBalance = onHoldOf(tokenHolder);
        netBalance = grossBalance.sub(onHoldBalance);
    }

    function onHoldOf(address tokenHolder) public view override returns (uint256 onHoldBalance) {
        onHoldBalance = 0;
        for (uint256 i = 0; i < _streams[tokenHolder].length; i++) {
            Stream memory stream = _streams[tokenHolder][i];
            if (stream.endTime > now) {
                uint256 timePassed = stream.endTime.sub(now);
                uint256 timeTotal = stream.endTime.sub(stream.startTime);
                onHoldBalance = stream.amount.mul(timePassed).div(timeTotal).add(onHoldBalance);
            }
        }
    }

    /**
     * @dev create a streaming transfer
     */
    function stream(address recipient, uint256 amount, bytes memory data, uint256 startTime, uint256 endTime) public override returns (bool) {
        _send(_msgSender(), recipient, amount, data, "", true);

        _streamId = _streamId.add(1);
        // Create Stream storage object
        Stream memory entry = Stream({
            streamId: _streamId,
            creator: _msgSender(),
            startTime: startTime,
            endTime: endTime,
            amount: amount
        });
        _streams[recipient].push(entry);
        _recipients[_streamId] = recipient;

        return true;
    }

    /**
     * @dev terminate a streaming transfer
     */
    function terminate(uint256 streamId) public override returns (bool) {
        address recipient = _recipients[streamId];
        require(recipient != address(0), "ERC777Streamable: stream not exists");

        for (uint256 i = 0; i < _streams[recipient].length; i++) {
            Stream memory entry = _streams[recipient][i];
            if (entry.streamId == streamId) {
                require(entry.creator == _msgSender(), "ERC777Streamable: only could stream's creator terminate a stream");
                if (entry.endTime > now) {
                    uint256 timePassed = entry.endTime.sub(now);
                    uint256 timeTotal = entry.endTime.sub(entry.startTime);
                    uint256 keptAmount = entry.amount.mul(timePassed).div(timeTotal);

                    entry.endTime = now;
                    _send(recipient, _msgSender(), entry.amount.sub(keptAmount), "", "", true);
                }

                // Cleanup storage
                _streams[recipient][i] = _streams[recipient][_streams[recipient].length.sub(1)];
                _streams[recipient].pop();

                delete _recipients[streamId];
                
                break;
            }
        }

        return true;
    }

    function _beforeTokenTransfer(address, address from, address, uint256 amount) internal override {
        require(from == address(0) || amount <= netBalanceOf(from), "ERC777: amount exceeds Net Balance");
    }
}
