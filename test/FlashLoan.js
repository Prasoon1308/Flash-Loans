const { expect } = require("chai");
const { ethers } = require("hardhat");

const tokens = (n) => {
  return ethers.utils.parseUnits(n.toString(), "ether");
};

describe("Flashloan", () => {
  let token, flashLoan, flashLoanReceiver;
  let deployer, user1;

  beforeEach(async () => {
    // Accounts setup
    accounts = await ethers.getSigners();
    deployer = accounts[0];

    // Loading contracts
    const FlashLoan = await ethers.getContractFactory("FlashLoan");
    const FlashLoanReceiver = await ethers.getContractFactory(
      "FlashLoanReceiver"
    );
    const Token = await ethers.getContractFactory("Token");

    // Deploying new token of name, symbol, total supply as Prasoon, PP and 100
    token = await Token.deploy("Prasoon", "PP", "100");

    // Deploying Flash Loan Pool
    flashLoan = await FlashLoan.deploy(token.address);

    // Approving tokens before the deposit
    let transaction = await token
      .connect(deployer)
      .approve(flashLoan.address, tokens(100));
    await transaction.wait();

    // Depositing tokens into the pool
    transaction = await flashLoan.connect(deployer).depositTokens(tokens(100));
    await transaction.wait();

    // Deploying Flash Loan Receiver
    flashLoanReceiver = await FlashLoanReceiver.deploy(flashLoan.address);
  });

  describe("Deployment", () => {
    it("sends tokens to the Crowdsale contract", async () => {
      expect(await token.balanceOf(flashLoan.address)).to.equal(tokens(100));
    });
  });

  describe("Borrowing funds", () => {
    it("borrows funds from the pool", async () => {
      let amount = tokens(100);
      let transaction = await flashLoanReceiver
        .connect(deployer)
        .executeFlashLoan(amount);
      let result = await transaction.wait();

      await expect(transaction)
        .to.emit(flashLoanReceiver, "LoanReceived")
        .withArgs(token.address, amount);
    });
  });
});
