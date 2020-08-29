from contract import Forge,NDAO,TOH
from privateKey import my_address, private_key
# from web3.auto.infura.rinkeby import w3
from web3.auto import w3
from os.path import dirname, abspath

eth_supply = int(112199718.41 * 10**18)
market_cap = int(48079823331 * 10 ** 18)

def setup():
    nonce = w3.eth.getTransactionCount(my_address)
    args =  [NDAO.address,eth_supply,market_cap]

    unicorn_txn = Forge.functions.Setup(*args).buildTransaction({
        'nonce': nonce,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=private_key)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("设置铸造合约交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("设置成功")
    else:
        print("设置失败")


def getInfo():
    ndao_address = Forge.functions.ndao().call()
    assert ndao_address == NDAO.address
    print("锻造合约的NDAO地址为:",ndao_address)

    eth = Forge.functions.eth_supply().call()
    assert eth == eth_supply
    print("当前ETH供应量为:",eth)

    ndao = Forge.functions.ndao_supply().call()
    assert ndao == market_cap
    print("当前NDAO供应量为:",ndao)


#从文件中读取SVG
def readSvg():
    path = dirname(dirname(abspath(__file__))) 
    with open(path  + "/test/quxian.svg") as file_object:
        contents = file_object.read()
        return contents


#设置SVG
def setSvg():
    svg = readSvg()
    nonce = w3.eth.getTransactionCount(my_address)
    unicorn_txn = TOH.functions.setSvg(svg).buildTransaction({
        'nonce': nonce,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=private_key)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("设置SVG图标的交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("设置成功")
    else:
        print("设置失败")


#获取某个tokenId对应的SVG图标
def viewSvg(tokenId):
    svg = TOH.functions.getTokenImageSvg(tokenId).call()
    print("svg_code:",svg)

# setup()
# getInfo()
viewSvg(1)

