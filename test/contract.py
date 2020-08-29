from web3.auto import w3
from json import loads
from os.path import dirname, abspath

def init():
    path = dirname(dirname(abspath(__file__)))
    froge_abi_path = path + '/build/contracts/forge.json'
    ndao_abi_path = path + '/build/contracts/NDAOToken.json'
    validator_abi_path = path + '/build/contracts/validator_registration_ndao.json'
    toh_abi_path = path + '/build/contracts/TOHContract.json'

    all_address_path = path + '/test/address.json'
    all_address = loads(open(all_address_path).read())

    contract_froge_abi = loads(open(froge_abi_path).read())['abi']
    contract_ndao_abi = loads(open(ndao_abi_path).read())['abi']
    contract_validator_abi = loads(open(validator_abi_path).read())['abi']
    contract_toh_abi = loads(open(toh_abi_path).read())['abi']

    forge_contract = w3.eth.contract(address=all_address["Forge"], abi=contract_froge_abi)
    ndao_contract = w3.eth.contract(address=all_address["NDAOToken"], abi=contract_ndao_abi)
    validtor_contract = w3.eth.contract(address=all_address["Validator"], abi=contract_validator_abi)
    toh_contract = w3.eth.contract(address=all_address["TOHContract"], abi=contract_toh_abi)
    return forge_contract,ndao_contract,validtor_contract,toh_contract

Forge,NDAO,Validator,TOH = init()
