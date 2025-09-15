// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.30;


import {IMiniAMM, IMiniAMMEvents} from "./IMiniAMM.sol";
import {MiniAMMLP} from "./MiniAMMLP.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";

// Add as many variables or functions as you would like
// for the implementation. The goal is to pass `forge test`.
contract MiniAMM is IMiniAMM, IMiniAMMEvents, MiniAMMLP {
    // 또는 더 정밀한 계산을 위해
    uint256 constant PRECISION = 1e18;
    uint256 public k = 0;
    uint256 public xReserve = 0;
    uint256 public yReserve = 0;

    address public tokenX;
    address public tokenY;

    // implement constructor
    constructor(address _tokenX, address _tokenY) MiniAMMLP(_tokenX, _tokenY) {
        require(_tokenX != _tokenY, "Tokens must be different");
        if(_tokenX == address(0)) {
            revert("tokenX cannot be zero address");
        }
        if(_tokenY == address(0)) {
            revert("tokenY cannot be zero address");
        }

        if(_tokenX < _tokenY) {
            tokenX = _tokenX;
            tokenY = _tokenY;
        }else {
            tokenX = _tokenY;
            tokenY = _tokenX;
        } 
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
        lpMinted = sqrt(xReserve * yReserve);
        _mintLP(msg.sender,lpMinted);
        k = xReserve * yReserve ;
        return lpMinted;  
    }

    // add parameters and implement function.
    // this function will increase the 'k'
    // because it is transferring liquidity from users to this contract.
    function _addLiquidityNotFirstTime(uint256 xAmountIn, uint256 yAmountIn) internal returns (uint256 lpMinted) {
    uint256 lpExisting = totalSupply();
    


    uint256 lpFromX = (xAmountIn * lpExisting * PRECISION) / xReserve / PRECISION;
    uint256 lpFromY = (yAmountIn * lpExisting * PRECISION) / yReserve / PRECISION;
    
    
    // 더 적은 쪽을 기준으로 LP 발행량 결정
    if (lpFromX <= lpFromY) {
        lpMinted = lpFromX;
        // X를 기준으로 Y 사용량 계산
        uint256 yUsed = (xAmountIn * yReserve) / xReserve;
        
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yUsed);
        
        xReserve += xAmountIn;
        yReserve += yUsed;
    } else {
        lpMinted = lpFromY;
        // Y를 기준으로 X 사용량 계산
        uint256 xUsed = (yAmountIn * xReserve) / yReserve;
        
        IERC20(tokenX).transferFrom(msg.sender, address(this), xUsed);
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
        
        xReserve += xUsed;
        yReserve += yAmountIn;
    }
    
    _mint(msg.sender, lpMinted);
    k = xReserve * yReserve;
    
    return lpMinted;
    }


    // complete the function. Should transfer LP token to the user.
    function addLiquidity(uint256 xAmountIn, uint256 yAmountIn) external returns (uint256 lpMinted) {
        if(xAmountIn == 0 || yAmountIn == 0) {
            revert("Amounts must be greater than 0");
        }

        if (k == 0) {
            // add params
            lpMinted = _addLiquidityFirstTime(xAmountIn,yAmountIn);
        } else {
            // add params
            lpMinted = _addLiquidityNotFirstTime(xAmountIn,yAmountIn);
        }

        emit AddLiquidity(xAmountIn, yAmountIn);
        
        return lpMinted;
    }

    // Remove liquidity by burning LP tokens
    function removeLiquidity(uint256 lpAmount) external returns (uint256 xAmount, uint256 yAmount) {
        require(lpAmount > 0, "LP amount must be positive");
        require(balanceOf(msg.sender) >= lpAmount, "Insufficient LP tokens");
        
        uint256 lpTotalSupply = totalSupply();
        require(lpTotalSupply > 0, "No liquidity");
        
        // 비례적으로 토큰 반환량 계산
        xAmount = (lpAmount * xReserve) / lpTotalSupply;
        yAmount = (lpAmount * yReserve) / lpTotalSupply;
        
        require(xAmount > 0 && yAmount > 0, "Insufficient liquidity burned");
        
        // LP 토큰 소각
        _burn(msg.sender, lpAmount);
        
        // 리저브 업데이트
        xReserve -= xAmount;
        yReserve -= yAmount;
        k = xReserve * yReserve;
        
        // 토큰 전송
        IERC20(tokenX).transfer(msg.sender, xAmount);
        IERC20(tokenY).transfer(msg.sender, yAmount);
        
        return (xAmount, yAmount);
    }

    // complete the function
    function swap(uint256 xAmountIn, uint256 yAmountIn) external {
    require(xReserve > 0 && yReserve > 0, "No liquidity in pool");
    require(xAmountIn != 0 || yAmountIn != 0, "Must swap at least one token");
    require(xAmountIn == 0 || yAmountIn == 0, "Can only swap one direction at a time");
    
    uint256 xAmountOut = 0;
    uint256 yAmountOut = 0;
    
    if (xAmountIn > 0) {
        // X → Y 스왑 (0.3% 수수료 적용)
        require(xAmountIn < xReserve, "Insufficient liquidity");
        
        // 수수료 적용: 99.7%만 실제 스왑에 사용
        uint256 xAmountInAfterFee = (xAmountIn * 997) / 1000;
        
        // AMM 공식으로 출력량 계산
        uint256 numerator = xAmountInAfterFee * yReserve;
        uint256 denominator = xReserve + xAmountInAfterFee;
        yAmountOut = numerator / denominator;
        
        require(yAmountOut > 0, "Insufficient output amount");
        require(yAmountOut < yReserve, "Insufficient liquidity");
        
        // 토큰 전송
        IERC20(tokenX).transferFrom(msg.sender, address(this), xAmountIn);
        IERC20(tokenY).transfer(msg.sender, yAmountOut);
        
        // 상태 업데이트
        xReserve += xAmountIn;
        yReserve -= yAmountOut;
        k = xReserve * yReserve;
        
        // 이벤트 발생: (xIn, yIn, xOut, yOut)
        emit Swap(xAmountIn, 0, 0, yAmountOut);
        
    } else {
        // Y → X 스왑 (0.3% 수수료 적용)
        require(yAmountIn < yReserve, "Insufficient liquidity");
        
        uint256 yAmountInAfterFee = (yAmountIn * 997) / 1000;
        
        uint256 numerator = yAmountInAfterFee * xReserve;
        uint256 denominator = yReserve + yAmountInAfterFee;
        xAmountOut = numerator / denominator;
        
        require(xAmountOut > 0, "Insufficient output amount");
        require(xAmountOut < xReserve, "Insufficient liquidity");
        
        IERC20(tokenY).transferFrom(msg.sender, address(this), yAmountIn);
        IERC20(tokenX).transfer(msg.sender, xAmountOut);
        
        yReserve += yAmountIn;
        xReserve -= xAmountOut;
        k = xReserve * yReserve;
        
        // 이벤트 발생: (xIn, yIn, xOut, yOut)
        emit Swap(0, yAmountIn, xAmountOut, 0);
    }
    }
}
