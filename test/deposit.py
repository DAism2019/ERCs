from contract import Forge,Validator,TOH,NDAO
from privateKey import my_address, private_key
# from web3.auto.infura.rinkeby import w3
from web3.auto import w3
import time  # 引入time模块

another = "0x2E8b222CFac863Ec6D3446c78fD46aAEA289A9fb"
another_privateKey = "078e9ed558a9afd1e7e27b9884fbcc95f8fa406bd02de3a2a19fbac401d7c74c"
approve_value = 2 ** 256 -1



FIXED_DEPOSIT_AMOUNT = 10000 * 10**18
FIXED_INPUT_AMOUNT = 23 * 10**18


def getOutputPrice():
    out_price = Forge.functions.getOutputPrice(FIXED_DEPOSIT_AMOUNT).call()
    print("当前所需要ETH价格为:",out_price/10 ** 18)
    return out_price

def getInputPrice():
    input_price = Forge.functions.getInputPrice(FIXED_INPUT_AMOUNT).call()
    print("当前锻造",FIXED_INPUT_AMOUNT/10**18,"ETH得到的NDAO为:",input_price/10 ** 18)
    return input_price


def depositByETH():
    eth_value = getOutputPrice()
    nonce = w3.eth.getTransactionCount(my_address)
    unicorn_txn = Validator.functions.depositByETHDemo().buildTransaction({
        'nonce': nonce,
        'value': eth_value,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=private_key)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("质押交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
    else:
        print("交易失败")


#授权质押合约
def approve():
    nonce = w3.eth.getTransactionCount(another)
    unicorn_txn = NDAO.functions.approve(Validator.address,approve_value).buildTransaction({
        'from': another,
        'nonce': nonce,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=another_privateKey)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("授权交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
    else:
        print("交易失败")

#获得NDAO余额
def getNDAOBalance(address):
    bal = NDAO.functions.balanceOf(address).call()
    print("当前地址:",address,"的NDAO余额为:",bal/10 ** 18)
    return bal


#使用ETH先锻造NDAO(input)
def forgeNDAOInput():
    old_bal = getNDAOBalance(another)
    out_ndao = getInputPrice()
    nonce = w3.eth.getTransactionCount(another)
    args = [out_ndao,int(time.time()) + 900,another]
    unicorn_txn = Forge.functions.ForgeNdaoInput(*args).buildTransaction({
        'from': another,
        'nonce': nonce,
        'value': FIXED_INPUT_AMOUNT,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=another_privateKey)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("锻造交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
        new_bal = getNDAOBalance(another)
        assert old_bal + out_ndao == new_bal
        print("测试成功")
    else:
        print("交易失败")



#使用ETH先锻造NDAO(output)
def forgeNDAOOutPut():
    getNDAOBalance(another)
    eth_value = getOutputPrice()
    nonce = w3.eth.getTransactionCount(another)
    args = [FIXED_DEPOSIT_AMOUNT,eth_value + 1000,int(time.time()) + 900,another,another]
    unicorn_txn = Forge.functions.ForgeNdaoOutput(*args).buildTransaction({
        'from': another,
        'nonce': nonce,
        'value': eth_value,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=another_privateKey)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("锻造交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
        getNDAOBalance(another)
    else:
        print("交易失败")


#使用NDAO质押
def depositByNDAO():
    nonce = w3.eth.getTransactionCount(another)
    unicorn_txn = Validator.functions.depositByNDAODemo().buildTransaction({
        'nonce': nonce,
        'from': another,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=another_privateKey)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("质押交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
    else:
        print("交易失败")


def getStartTime(address):
    start_time = Validator.functions.registration_times(address).call()
    print("地址为",address,"的账号的质押时间为:",start_time)
    ticks = int(time.time())
    maxi = (ticks - start_time) //60
    print("从开始时间计算的最大等级为:",maxi)


def getMaxLevel(address):
    max_level = TOH.functions.calMaxLevel(address).call()
    print("合约可以领取勋章的最大等级为:",max_level)
    return max_level


def withdrawAnother(level):
    max_level = getMaxLevel(another)
    assert level <= max_level
    nonce = w3.eth.getTransactionCount(another)
    unicorn_txn = TOH.functions.withDrawToken(level).buildTransaction({
        'from': another,
        'nonce': nonce,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=another_privateKey)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("领取交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
        getMaxLevel(another)
    else:
        print("交易失败")




def withdraw(level):
    max_level = getMaxLevel(my_address)
    assert level <= max_level
    nonce = w3.eth.getTransactionCount(my_address)
    unicorn_txn = TOH.functions.withDrawToken(level).buildTransaction({
        'nonce': nonce,
        'gasPrice': 6 * (10 ** 9)
    })
    signed_txn = w3.eth.account.signTransaction(
        unicorn_txn, private_key=private_key)
    hash = w3.eth.sendRawTransaction(signed_txn.rawTransaction)
    print("领取勋章交易已经发送")
    result = w3.eth.waitForTransactionReceipt(hash)
    if result.status == 1:
        print("交易成功")
        getMaxLevel(my_address)
    else:
        print("交易失败")


def getBalance(address):
    bal = TOH.functions.balanceOf(address).call()
    print("我的纪念币数量为:",bal)


def getTokenInfos(tokenId):
    infos = TOH.functions.tokenInfos(tokenId).call()
    [val,level] = infos
    print("当前ID为",tokenId,"的勋章的验证者为:",val)
    print("当前ID为",tokenId,"的勋章的等级为:",level)


# depositByETH() #只能投资一次

# approve()
# forgeNDAO()
# depositByNDAO()
# forgeNDAOInput()
getTokenInfos(5)
# withdrawAnother(5)
