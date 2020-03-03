const Mutatio = artifacts.require("Mutatio");
// const MaybeDai = artifacts.require("MaybeDai");
const JALToken = artifacts.require("JALToken");

module.exports = function(deployer) {
  deployer.deploy(JALToken);
  deployer.deploy(Mutatio, "0x243e777986d7f32912CEc7E67B7f07CE412f58E6", JALToken.address);
  // deployer.deploy(MaybeDai);
  
};