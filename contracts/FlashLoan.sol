// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "hardhat/console.sol";
import "./Token.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

interface IReceiver {
    function receiveTokens(address tokenAddress, uint256 amount) external;
}

contract FlashLoan is ReentrancyGuard {
    using SafeMath for uint256;

    Token public token;
    uint256 public poolBalance;

    constructor(address _tokenAddress) {
        token = Token(_tokenAddress);
    }

    function depositTokens(uint _amount) external nonReentrant {
        require(_amount > 0, "Must deposit atleast one token");
        token.transferFrom(msg.sender, address(this), _amount);
        poolBalance = poolBalance.add(_amount);
    }

    function flashLoan(uint256 _borrowAmount) external nonReentrant {
        require(_borrowAmount > 0, "Must borrow atleast one token");

        uint256 balanceBefore = token.balanceOf(address(this));
        require(
            balanceBefore >= _borrowAmount,
            "Not wnough tokens in the pool"
        );

        // Ensured by the protocol via 'depositTokens' function
        assert(poolBalance == balanceBefore);
        // Send tokens to receiver
        token.transfer(msg.sender, _borrowAmount);
        // Using loan and Get paid back
        IReceiver(msg.sender).receiveTokens(address(token), _borrowAmount);
        // Ensure loan is paid back
        uint256 balanceAfter = token.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash Loan hasn't been paid back"
        );
    }
}
