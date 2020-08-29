const Forge = artifacts.require("forge");
module.exports = function(deployer) {
  // deployer.deploy(Forge,{overwrite:false});
  deployer.deploy(Forge);
};