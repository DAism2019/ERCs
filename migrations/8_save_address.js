const fsService = require('../scripts/fileService');
const fileName = "./test/address.json";

const Forge = artifacts.require("forge");
const NDAOToken = artifacts.require("NDAOToken");
const Validator = artifacts.require("validator_registration_ndao");
const TOHContract = artifacts.require("TOHContract");


const data = {
    "Forge": Forge.address,
    "NDAOToken":NDAOToken.address,
    "Validator": Validator.address,
    "TOHContract":TOHContract.address
}

module.exports = function(deployer) {
    fsService.writeJson(fileName, data);
    console.log('address save over');
};
