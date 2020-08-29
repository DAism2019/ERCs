from contract import Forge

FIXED_DEPOSIT_AMOUNT = 10000 * 10**18

print("投资数量为:",FIXED_DEPOSIT_AMOUNT)

def getEthSupply():
    eth = Forge.functions.eth_supply().call()
    print("当前ETH供应量为:",eth/10 **18)
    ndao = Forge.functions.ndao_supply().call()
    print("当前NDAO供应量为:",ndao/10 ** 18)
    return eth,ndao


def calOutPrice():
    eth, ndao = getEthSupply()
    mul = eth * ndao
    new_ndao = ndao + FIXED_DEPOSIT_AMOUNT
    new_eth = mul / new_ndao
    eth_price = eth - new_eth + 1
    print("计算output价格为:",eth_price/10 ** 18)

def getOutprice():
    out_price = Forge.functions.getOutputPrice(FIXED_DEPOSIT_AMOUNT).call()
    print("合约output价格为:",out_price/10 ** 18)


calOutPrice()
getOutprice()