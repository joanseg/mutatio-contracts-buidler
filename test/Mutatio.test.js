const Mutatio = artifacts.require('Mutatio');
const JALToken = artifacts.require('JALToken');

let catchRevert = require("./exceptionsHelpers.js").catchRevert;


// exceptionsHelpers.js will facilitate some functions to test our contract
// let catchRevert = require("./exceptionsHelpers.js").catchRevert;

const BN = web3.utils.BN;

let mutatio;

contract('Mutatio', (accounts) => {
  let tokenAddress
  const amountToken = '100'

  let token;
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
  });

  describe('Mutatio Contract', () => {
      it('deploys a contract', () => {
        assert.ok(mutatio.address);
      });

      it('deposit function should emit an event with the exchange parameters', async () => {
        const tx = await mutatio.exchangeEth(
          tokenAddress, 
          amountToken
        );
        const events = tx.logs[0].args;
        console.log(tokenAddress, events.targetToken);
        assert.equal(amountToken, events.amountToken);
      });
    });

  describe('exchangeStarted()', () => {
    it('just an exchange should be able to call exchangeStarted()', async () => {
      const tx = await mutatio.exchangeEth(
        tokenAddress, 
        amountToken
      );
      const orderId = tx.logs[0].args.orderId;
      await mutatio.exchangeStarted(orderId, {from: exchangeAddress})
      await catchRevert(mutatio.exchangeStarted(orderId, {from: anotherAddress}))
    })
    it('should assign the exchange address to the order and turn the start flag', async () => {
      await mutatio.exchangeEth(
        tokenAddress,
        amountToken,
        {from: buyerAccount}
      );
      await mutatio.exchangeStarted(1, {from: exchangeAddress});
      // const orderId = tx.logs[0].args.orderId;
      // const order = await mutatio.exchangeStarted(orderId, {from: exchangeAddress});

      const orderDetails = await mutatio.readOrder.call(1);
      
      assert.equal(orderDetails.exchangeAddress, exchangeAddress, "The address should be equal to the exchange address")
      assert.equal(orderDetails.exchangeStarted, true, "The order should be started")
    });
  });

  describe('exchangeCompleted()', async () => {
    it('The transferFrom function should return true if an exchange calls this method and has the funds', async () => {
      await token.transfer(exchangeAddress, 1000, {from: deployAccount})
      await token.approve(mutatio.address, 1000, {from: exchangeAddress})
      const tx = await mutatio.exchangeEth(
        tokenAddress, 
        amountToken
      );

      const result = await mutatio.exchangeCompleted(1, 100, {from: exchangeAddress})
      // console.log(result)

      //assert.equal(result, true, "The exchange should be able to complete")
    });
  });
});

