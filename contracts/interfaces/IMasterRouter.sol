// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.4;

interface IMasterRouter {
    function swap(
        address _tokenIn,
        address _tokenOut,
        uint256 _amountIn,
        uint256 _minAmountOut,
        address _to,
        bytes calldata _data,
        uint256 _deadline
    ) external payable returns (uint256 amountOut);
}
