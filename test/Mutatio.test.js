const Mutatio = artifacts.require('Mutatio');
const JALToken = artifacts.require('JALToken');

let catchRevert = require("./exceptionsHelpers.js").catchRevert;


// exceptionsHelpers.js will facilitate some functions to test our contract
// let catchRevert = require("./exceptionsHelpers.js").catchRevert;

const BN = web3.utils.BN;

let mutatio;

contract('Mutatio', (accounts) => {
  let tokenAddress
  const ethSold = 10000 
  const minTokens = 100
  const deadline = Date.now() + 90000 // now plus 15 minutes


  let token
  const deployAccount = accounts[0]
  const buyerAccount = accounts[1]
  const exchangeAddress = accounts[3]
  const anotherAddress = accounts[2]

  beforeEach( async ()=> {
      // Get list of all accounts       
      accounts = await web3.eth.getAccounts();
      token = await JALToken.new();
      mutatio = await Mutatio.new(exchangeAddress, token.address);
      tokenAddress = token.address;
      exchangeAddressBalance = await web3.eth.getBalance(exchangeAddress);

  });

  describe('Mutatio Contract', () => {
      it('deploys a contract', () => {
        console.log("Mutatio contract deployed on address: ", mutatio.address)
        assert.ok(mutatio.address);
      });

      it('deposit function should emit an event with the ethToTokenSwap parameters', async () => {
        const tx = await mutatio.ethToTokenSwap(
          tokenAddress, 
          minTokens,
          deadline,
          {from: buyerAccount, value: ethSold}
        );
        const ethToTokenSwapEvents = tx.logs[0].args;
        console.log(tokenAddress, ethToTokenSwapEvents.tokenAddress, ethSold);
        assert.equal(ethSold, ethToTokenSwapEvents.ethSold, "ethSold does not match");
        assert.equal(tokenAddress, ethToTokenSwapEvents.tokenAddress, "tokenAddress does not match");
        assert.equal(minTokens, ethToTokenSwapEvents.minTokens, "mintTokens does not match");
        assert.equal(deadline, ethToTokenSwapEvents.deadline, "deadline does not match");
        assert.equal(buyerAccount, ethToTokenSwapEvents.buyer, "buyerAccount does not match");
        assert.equal(buyerAccount, ethToTokenSwapEvents.recipient, "recipient account does not match");
      });
    });

  // describe('exchangeStarted()', () => {
  //   it('just an exchange should be able to call exchangeStarted()', async () => {
  //     const tx = await mutatio.exchangeEth(
  //       tokenAddress, 
  //       amountToken
  //     );
  //     const orderId = tx.logs[0].args.orderId;
  //     await mutatio.exchangeStarted(orderId, {from: exchangeAddress})
  //     await catchRevert(mutatio.exchangeStarted(orderId, {from: anotherAddress}))
  //   })
  //   it('should assign the exchange address to the order and turn the start flag', async () => {
  //     await mutatio.exchangeEth(
  //       tokenAddress,
  //       amountToken,
  //       {from: buyerAccount}
  //     );
  //     await mutatio.exchangeStarted(1, {from: exchangeAddress});
  //     // const orderId = tx.logs[0].args.orderId;
  //     // const order = await mutatio.exchangeStarted(orderId, {from: exchangeAddress});

  //     const orderDetails = await mutatio.readOrder.call(1);
      
  //     assert.equal(orderDetails.exchangeAddress, exchangeAddress, "The address should be equal to the exchange address")
  //     assert.equal(orderDetails.exchangeStarted, true, "The order should be started")
  //   });
  // });

  describe('ethToTokenSwapExchangeCompleted()', async () => {
    it('The function ethToTokenSwapExchangeCompleted() should succeed if the exchange transfers enough tokens', async () => {
      await token.transfer(exchangeAddress, 1000, {from: deployAccount}) //Mutatio contract transfers tokens from this contract to the exchange
      await token.approve(mutatio.address, 1000, {from: exchangeAddress}) //exchangeAddress grants permission to Mutatio to transferFrom tokens
      await mutatio.ethToTokenSwap(
        tokenAddress, 
        minTokens,
        deadline,
        {from: buyerAccount, value: ethSold}
      );

      await assert.ok(mutatio.ethToTokenSwapExchangeCompleted(1, minTokens, {from: exchangeAddress}), "ethToTokenSwapExchangeCompleted() failed")
      //assert.equal(result, true, "The exchange should be able to complete")
    });
    it('The function ethToTokenSwapExchangeCompleted() should fail if the exchange does not transfers enough tokens', async () => {
      await token.transfer(exchangeAddress, 1000, {from: deployAccount}) //Mutatio contract transfers tokens from this contract to the exchange
      await token.approve(mutatio.address, 1000, {from: exchangeAddress}) //exchangeAddress grants permission to Mutatio to transferFrom tokens
      await mutatio.ethToTokenSwap(
        tokenAddress, 
        minTokens,
        deadline,
        {from: buyerAccount, value: ethSold}
      );

      await catchRevert(mutatio.ethToTokenSwapExchangeCompleted(1, minTokens - 1, {from: exchangeAddress}))
    });
  });
  describe('ethToTokenSwapExchangeCompleted()', async () => {
    it('The function ethToTokenSwapEscrowCompleted() should transfer to the exchange the ethSold amount', async () => {
    console.log(exchangeAddressBalance)
    await token.transfer(exchangeAddress, 1000, {from: deployAccount}) //Mutatio contract transfers tokens from this contract to the exchange
    await token.approve(mutatio.address, 1000, {from: exchangeAddress}) //exchangeAddress grants permission to Mutatio to transferFrom tokens
    await mutatio.ethToTokenSwap(
      tokenAddress, 
      minTokens,
      deadline,
      {from: buyerAccount, value: ethSold}
    );
    await mutatio.ethToTokenSwapExchangeCompleted(1, minTokens, {from: exchangeAddress})
    let newExhangeAddressBalance = await web3.eth.getBalance(exchangeAddress)
    let increment = newExhangeAddressBalance - exchangeAddressBalance
    console.log(exchangeAddressBalance)
    console.log(newExhangeAddressBalance)

    assert.equal(newExhangeAddressBalance, exchangeAddressBalance, "exchange did not receive the ethSold amount" )

    });
  });
});

