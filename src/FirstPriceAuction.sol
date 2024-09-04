// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IConditionalOrder} from "lib/composable-cow/src/interfaces/IConditionalOrder.sol";
import {BaseConditionalOrder} from "lib/composable-cow/src/BaseConditionalOrder.sol";
import {ComposableCoW} from "lib/composable-cow/src/ComposableCoW.sol";
import {GPv2Order, IERC20} from "cowprotocol/contracts/libraries/GPv2Order.sol";

contract FirstPriceAuction is BaseConditionalOrder {
    ComposableCoW public immutable composableCow;
    IERC20 public immutable hype;
    IERC20 public immutable syntheticToken;
    uint32 public immutable biddingDeadline;

    constructor(address _composableCow, address _hype, address _syntheticToken, uint32 _biddingWindow) {
        composableCow = ComposableCoW(_composableCow);
        hype = IERC20(_hype);
        syntheticToken = IERC20(_syntheticToken);
        biddingDeadline = uint32(block.timestamp) + _biddingWindow;
    }

    function createBid(uint256 amount) public {
        IConditionalOrder.ConditionalOrderParams memory params = IConditionalOrder.ConditionalOrderParams({
            handler: IConditionalOrder(address(this)),
            salt: keccak256(abi.encode(block.timestamp)),
            staticInput: abi.encode(amount)
        });
        composableCow.create(params, true);
    }

    function approveSyntheticToken(address spender, uint256 amount) public {
        syntheticToken.approve(spender, amount);
    }

    function getTradeableOrder(address, address, bytes32, bytes calldata staticInput, bytes calldata offchainInput)
        public
        view
        override
        returns (GPv2Order.Data memory order)
    {
        if (!(block.timestamp >= biddingDeadline)) {
            revert IConditionalOrder.PollTryAtEpoch(biddingDeadline, "too early");
        }

        uint256 buyAmount = abi.decode(offchainInput, (uint256));

        order = GPv2Order.Data(
            syntheticToken,
            hype,
            msg.sender,
            syntheticToken.balanceOf(address(this)),
            buyAmount, // 0 set
            biddingDeadline + 7 days,
            0x0,
            0,
            GPv2Order.KIND_SELL,
            false,
            GPv2Order.BALANCE_ERC20,
            GPv2Order.BALANCE_ERC20
        );
    }
}
