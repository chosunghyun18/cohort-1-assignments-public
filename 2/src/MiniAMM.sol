// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;

import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {MiniAMMLP} from "./MiniAMMLP.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents, MiniAMMLP {
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) MiniAMMLP(_tokenX, _tokenY) {
    }

    // Helper function to calculate square root
    function sqrt(uint256 x) internal pure returns (uint256) {
        if (x == 0) return 0;
        uint256 z = (x + 1) / 2;
        uint256 y = x;
        while (z < y) {
            y = z;
            z = (x / z + z) / 2;
        }
        return y;
    }

    // add parameters and implement function.
    // this function will determine the 'k'.
    function _addLiquidityFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal returns (uint256 lpMinted) {
        IERC20(tokenX).transferFrom(msg.sender,address(this),xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender,address(this),yAmountIn);

        xReserve = xAmountIn;
        yReserve = yAmountIn;

        k = xReserve * yReserve ;
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn) internal returns (uint256 lpMinted) {
    
        IERC20(tokenX).transferFrom(msg.sender,address(this),xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender,address(this),yAmountIn);

        xReserve += xAmountIn;
        yReserve += yAmountIn;

        k = xReserve * yReserve ;
    }

    // complete the function. Should transfer LP token to the user.
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external returns (uint256 lpMinted) {
        if(xAmountIn == 0 || yAmountIn == 0) {
            revert("Amounts must be greater than 0");
        }

        if (k == 0) {
            // add params
            _addLiquidityFirstTime(xAmountIn,yAmountIn);
        } else {
            // add params
            _addLiquidityNotFirstTime(xAmountIn,yAmountIn);
        }

        emit AddLiquidity(xAmountIn, yAmountIn);
    }

    // Remove liquidity by burning LP tokens
    function removeLiquidity(uint256 lpAmount) external returns (uint256 xAmount, uint256 yAmount) {
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
        if( xReserve == 0 && yReserve == 0 && k ==0) {
            revert("No liquidity in pool");
        }

        if( xAmountIn != 0  &&  yAmountIn  != 0) {
            revert("Can only swap one direction at a time") ;
        }

        if( xAmountIn == 0  &&  yAmountIn  == 0) {
            revert("Must swap at least one token") ;
        }

        if (xAmountIn > xReserve || yAmountIn > yReserve) {
            revert("Insufficient liquidity");
        }
        uint256 xAmountReturn = 0;
        uint256 yAmountReturn = 0;

        if (yAmountIn == 0) {
            xReserve += xAmountIn;
            yAmountReturn = yReserve - (k / xReserve);
            if (yAmountReturn > yReserve) {
                revert("Insufficient liquidity");
            }
            yReserve -= yAmountReturn;
            IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
            IERC20(tokenY).transfer(msg.sender, yAmountReturn);
            emit Swap(xAmountIn, yAmountReturn);
        } else {
           yReserve += yAmountIn;
            xAmountReturn = xReserve - (k / yReserve);
            if (xAmountReturn > xReserve) {
                revert("Insufficient liquidity");
            }
            xReserve -= xAmountReturn;
            IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
            IERC20(tokenX).transfer(msg.sender, xAmountReturn);
            emit Swap(xAmountReturn, yAmountIn);
        }
    }
}
