const {web3, artifacts} = require("@nomiclabs/buidler")

const Token = artifacts.require("JALToken");
const Mutatio = artifacts.require("Mutatio");

async function main() {
    const accounts = await web3.eth.getAccounts()
    const token = await Token.new();
    console.log("Token deployed at", token.address);

    const mutatio = await Mutatio.new(accounts[3], token.address)
    console.log("Mutatio deployed to", mutatio.address)
}

main().then(process.exit).catch(console.error)