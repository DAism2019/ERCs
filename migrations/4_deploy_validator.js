const NDAOToken = artifacts.require("NDAOToken");
const Forge = artifacts.require("forge");
const Validator = artifacts.require("validator_registration_ndao");
module.exports = function(deployer) {
  // deployer.deploy(Validator,NDAOToken.address,Forge.address,{overwrite:false});
  deployer.deploy(Validator,NDAOToken.address,Forge.address);
};