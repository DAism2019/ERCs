# @version ^0.2.4
"""
@title A contract of forging eth to ndao
@license MIT
@author radarzhhua
"""


interface NDAO:
    def mint(_to: address, _value: uint256):nonpayable

event ForgeETH:
    _from : indexed(address)
    eth_amount:uint256
    ndao_amount:uint256


#NDAO地址
ndao: public(address)
#恒定乘积所需要的ETH数量及NDAO数量(市值)
eth_supply:public(uint256)
ndao_supply:public(uint256)


#构造函数
@external
def Setup(_ndao:address,_eth_supply:uint256,_ndao_supply:uint256):
    """
    @dev constructor
    @param _ndao The address of  ndao token 
    @param _eth_supply The supply of eth
    @param _ndao_supply The market capability of eth
    """
    assert self.ndao == ZERO_ADDRESS, "has setup"
    assert _ndao != ZERO_ADDRESS, "ZERO_ADDRESS"
    assert _eth_supply > 0 and _ndao_supply > 0, "ZERO_SUPPLY"
    self.ndao = _ndao
    self.eth_supply = _eth_supply
    self.ndao_supply = _ndao_supply


#根据锻造的ETH数量计算产出的NDAO
@internal
@view
def _ethToNdaoInputPrice(eth_input_amount:uint256) -> uint256:
    assert eth_input_amount > 0, "ZERO_ETH_AMOUNT"
    assert self.eth_supply > 0 and self.ndao_supply > 0 ,"ZERO CPMM"
    numerator:uint256 = self.ndao_supply * eth_input_amount 
    denominator:uint256 = self.eth_supply - eth_input_amount
    return numerator/denominator


@external
def getInputPrice(eth_input_amount:uint256) -> uint256:
    return self._ethToNdaoInputPrice(eth_input_amount)


#根据产出的NDAO计算所需要的ETH
@internal
@view
def _ethToNdaoOutputPrice(ndao_out_amount:uint256) -> uint256:
    assert ndao_out_amount > 0, "ZERO_NDAO_AMOUNT"
    assert self.eth_supply > 0 and self.ndao_supply > 0 ,"ZERO CPMM"
    numerator:uint256 = self.eth_supply * ndao_out_amount
    denominator:uint256 = self.ndao_supply + ndao_out_amount
    return numerator/denominator + 1


@external
def getOutputPrice(ndao_out_amount:uint256) -> uint256:
    return self._ethToNdaoOutputPrice(ndao_out_amount)


#锻造ETH获取NDAO
@payable
@external
@nonreentrant("forge")
def ForgeNdaoInput(min_ndao:uint256,deadline:uint256,recipient:address) -> uint256:
    """
    @dev Forge eth to ndao input
    @param mit_ndao The minimum of output ndao 
    @param deadline Time after which this transaction can no longer be executed
    @param recipient The address that receives output ndao
    @return Amount of output ndao
    """
    assert deadline >= block.timestamp, "Transaction time out"
    assert recipient != ZERO_ADDRESS, "ZERO_ADDRESS"

    out_ndao:uint256 = self._ethToNdaoInputPrice(msg.value)
    assert out_ndao >= min_ndao, "Out ndao is less than minimum"

    self.eth_supply -= msg.value
    self.ndao_supply +=  out_ndao

    NDAO(self.ndao).mint(recipient,out_ndao)
    log ForgeETH(msg.sender,msg.value,out_ndao)
    return out_ndao


@payable
@external
@nonreentrant("forge")
def ForgeNdaoOutput(ndao_amount:uint256,max_eth:uint256,deadline:uint256,buyer:address,recipient:address) -> uint256:
    """
    @dev Forge eth to ndao output
    @param ndao_amount The amount of output ndao
    @param max_eth The maximum of eth to be forged
    @param deadline Time after which this transaction can no longer be executed
    @param recipient The address that receives output ndao
    @return Amount of input eth
    """
    assert deadline >= block.timestamp, "Transaction time out"
    assert max_eth >0, "ZERO_MAXIMUM"
    assert recipient != ZERO_ADDRESS and buyer != ZERO_ADDRESS, "ZERO_ADDRESS"

    input_eth:uint256 = self._ethToNdaoOutputPrice(ndao_amount)
    assert input_eth > 0, "Price is zero"
    assert input_eth <= max_eth, "Input eth is greater than maximum"
    assert msg.value >= input_eth, "Insufficient eth"

    self.eth_supply -= input_eth
    self.ndao_supply +=  ndao_amount

    NDAO(self.ndao).mint(recipient,ndao_amount)
    send(buyer,msg.value - input_eth)
    log ForgeETH(buyer,input_eth,ndao_amount)
    return input_eth


