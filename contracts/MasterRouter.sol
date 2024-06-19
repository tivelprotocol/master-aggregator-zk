// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

import "./libraries/TransferHelper.sol";
import "./interfaces/IERC20.sol";
import "./interfaces/external/IWETH9.sol";
import "./interfaces/IAggregator.sol";
import "./interfaces/IMasterRouter.sol";

contract MasterRouter is IMasterRouter {
    IAggregator public aggregator;
    IWETH9 public WETH;
    address private constant WETH_REPLACEMENT =
        0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    error Expired();
    error IdenticalTokens();
    error InsufficientInput();

    constructor(IAggregator _aggregator, IWETH9 _WETH) {
        aggregator = _aggregator;
        WETH = _WETH;
    }

    receive() external payable {
        assert(msg.sender == address(WETH)); // only accept ETH via fallback from the WETH contract
    }

    modifier ensure(uint256 _deadline) {
        if (_deadline < block.timestamp) revert Expired();
        _;
    }

    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        bytes calldata _data,
        uint256 _deadline
    ) external payable override ensure(_deadline) returns (uint256 amountOut) {
        if (_tokenIn == _tokenOut) revert IdenticalTokens();
        IAggregator _aggregator = aggregator;

        // transfer tokenIn to aggregator
        if (_tokenIn == WETH_REPLACEMENT) {
            if (msg.value < _amountIn) revert InsufficientInput();
            WETH.deposit{value: _amountIn}();
            assert(WETH.transfer(address(_aggregator), _amountIn));
            _tokenIn = address(WETH);
        } else {
            TransferHelper.safeTransferFrom(
                _tokenIn,
                msg.sender,
                address(_aggregator),
                _amountIn
            );
        }

        // swap
        if (_tokenOut == WETH_REPLACEMENT) {
            amountOut = aggregator.swap(
                _tokenIn,
                _tokenOut,
                _minAmountOut,
                address(this),
                _data
            );
            WETH.withdraw(amountOut);
            TransferHelper.safeTransferETH(_to, amountOut);
        } else {
            amountOut = aggregator.swap(
                _tokenIn,
                _tokenOut,
                _minAmountOut,
                _to,
                _data
            );
        }
    }
}
