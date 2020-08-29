const NDAOToken = artifacts.require("NDAOToken");
const Forge = artifacts.require("forge");
module.exports = function(deployer) {
  // deployer.deploy(NDAOToken,Forge.address,{overwrite:false});
  deployer.deploy(NDAOToken,Forge.address);
};