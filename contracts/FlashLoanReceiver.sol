// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./FlashLoan.sol";
import "./Token.sol";
import "hardhat/console.sol";

contract FlashLoanReceiver {
    FlashLoan private pool;
    address private owner;

    event LoanReceived(address token, uint256 amount);

    constructor(address _poolAddress) {
        pool = FlashLoan(_poolAddress);
        owner = msg.sender;
    }

    function receiveTokens(address _tokenAddress, uint256 _amount) external {
        require(msg.sender == address(pool), "Sender must be pool");
        // Require funds received
        require(
            Token(_tokenAddress).balanceOf(address(this)) == _amount,
            "Failed to get loan"
        );

        // Emit the Loan Received event
        emit LoanReceived(_tokenAddress, _amount);

        // do stuff with the loan money

        // Return funds to the pool
        require(
            Token(_tokenAddress).transfer(msg.sender, _amount),
            "Transfer of tokens failed"
        );
    }

    function executeFlashLoan(uint256 _amount) external {
        require(msg.sender == owner, "Only owner can execute the flash loans");
        pool.flashLoan(_amount);
    }
}
