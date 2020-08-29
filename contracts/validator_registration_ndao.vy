# @version ^0.2.4
FIXED_DEPOSIT_AMOUNT: constant(uint256) = 10000  #最小质押ndao数量
DEPOSIT_CONTRACT_TREE_DEPTH: constant(uint256) = 32  #质押合约默克尔树深度
MAX_DEPOSIT_COUNT: constant(uint256) = 4294967295 # 最大质押次数（2**DEPOSIT_CONTRACT_TREE_DEPTH - 1）
PUBKEY_LENGTH: constant(uint256) = 48  # Bytes 公钥长度  BLS pubkey ，
WITHDRAWAL_CREDENTIALS_LENGTH: constant(uint256) = 32  # Bytes 该证书由前缀加提币公钥的哈希计算而来
SIGNATURE_LENGTH: constant(uint256) = 96  # Bytes 签名长度
AMOUNT_LENGTH: constant(uint256) = 8  # Bytes


interface NDAOToken:
    def transferFrom(_from : address, _to : address, _value : uint256) -> bool:nonpayable

interface Forge:
    def ForgeNdaoOutput(ndao_amount:uint256,max_eth:uint256,deadline:uint256,buyer:address,recipient:address) -> uint256:payable


event DepositEvent:
    pubkey: Bytes[PUBKEY_LENGTH]
    withdrawal_credentials:Bytes[WITHDRAWAL_CREDENTIALS_LENGTH]
    amount:Bytes[AMOUNT_LENGTH]
    signature:Bytes[SIGNATURE_LENGTH]
    index: Bytes[8]


branch: bytes32[DEPOSIT_CONTRACT_TREE_DEPTH]  
deposit_count: public(uint256)
# Compute hashes in empty sparse Merkle tree
zero_hashes: bytes32[DEPOSIT_CONTRACT_TREE_DEPTH]
registration_times: public(HashMap[address, uint256])
ndao:public(address)
forge:public(address)


@external
def __init__(_ndao:address, _forge:address):
    assert _ndao != ZERO_ADDRESS and _forge != ZERO_ADDRESS, "ZERO_ADDRESS"
    self.ndao = _ndao
    self.forge = _forge
    for i in range(DEPOSIT_CONTRACT_TREE_DEPTH - 1):
        self.zero_hashes[i + 1] = sha256(concat(self.zero_hashes[i], self.zero_hashes[i]))


@pure
@internal
def to_little_endian_64(_value:uint256) -> Bytes[8]:
    # Reversing Bytes using bitwise uint256 manipulations
    # Note: array accesses of Bytes[] are not currently supported in Vyper
    # Note: this function is only called when `_value < 2**64`
    y: uint256 = 0
    x: uint256 = _value
    for _ in range(8):
        y = shift(y, 8)
        y = y + bitwise_and(x, 255)
        x = shift(x, -8)
    return slice(convert(y, bytes32), 24, 8)


@view
@external
def get_deposit_root() -> bytes32:
    zero_bytes32: bytes32 = EMPTY_BYTES32
    node: bytes32 = zero_bytes32
    size: uint256 = self.deposit_count
    for height in range(DEPOSIT_CONTRACT_TREE_DEPTH):
        if bitwise_and(size, 1) == 1:  # More gas efficient than `size % 2 == 1`
            node = sha256(concat(self.branch[height], node))
        else:
            node = sha256(concat(node, self.zero_hashes[height]))
        size /= 2
    return sha256(concat(node, self.to_little_endian_64(self.deposit_count), slice(zero_bytes32, 0, 24)))


@view
@external
def get_deposit_count() -> Bytes[8]:
    return self.to_little_endian_64(self.deposit_count)


@internal
def _saveInfo(pubkey: Bytes[PUBKEY_LENGTH],
            withdrawal_credentials: Bytes[WITHDRAWAL_CREDENTIALS_LENGTH],
            signature: Bytes[SIGNATURE_LENGTH],
            deposit_data_root: bytes32):
    # Length checks for safety
    assert len(pubkey) == PUBKEY_LENGTH
    assert len(withdrawal_credentials) == WITHDRAWAL_CREDENTIALS_LENGTH
    assert len(signature) == SIGNATURE_LENGTH

    # Emit `DepositEvent` log
    amount: Bytes[8] = self.to_little_endian_64(FIXED_DEPOSIT_AMOUNT)
    log DepositEvent(pubkey, withdrawal_credentials, amount, signature, self.to_little_endian_64(self.deposit_count))

    # Compute deposit data root (`DepositData` hash tree root)
    zero_bytes32: bytes32 = EMPTY_BYTES32
    pubkey_root: bytes32 = sha256(concat(pubkey, slice(zero_bytes32, 0, 64 - PUBKEY_LENGTH)))
    signature_root: bytes32 = sha256(concat(
        sha256(slice(signature, 0, 64)),
        sha256(concat(slice(signature, 64, SIGNATURE_LENGTH - 64), zero_bytes32)),
    ))
    node: bytes32 = sha256(concat(
        sha256(concat(pubkey_root, withdrawal_credentials)),
        sha256(concat(amount, slice(zero_bytes32, 0, 32 - AMOUNT_LENGTH), signature_root)),
    ))
    # Verify computed and expected deposit data roots match
    assert node == deposit_data_root

    # Add deposit data root to Merkle tree (update a single `branch` node)
    self.deposit_count += 1
    size: uint256 = self.deposit_count
    for height in range(DEPOSIT_CONTRACT_TREE_DEPTH):
        if bitwise_and(size, 1) == 1:  # More gas efficient than `size % 2 == 1`
            self.branch[height] = node
            break
        node = sha256(concat(self.branch[height], node))
        size /= 2


@external
def depositByNdao(pubkey: Bytes[PUBKEY_LENGTH],
            withdrawal_credentials: Bytes[WITHDRAWAL_CREDENTIALS_LENGTH],
            signature: Bytes[SIGNATURE_LENGTH],
            deposit_data_root: bytes32):
    # Avoid overflowing the Merkle tree (and prevent edge case in computing `self.branch`)
    assert self.deposit_count < MAX_DEPOSIT_COUNT
    assert  self.registration_times[msg.sender] == 0, "has deposited"
    self.registration_times[msg.sender] = block.timestamp
    # Check deposit amount
    result:bool = NDAOToken(self.ndao).transferFrom(msg.sender,self,FIXED_DEPOSIT_AMOUNT * (10 ** 18))
    assert result
    self._saveInfo(pubkey,withdrawal_credentials,signature,deposit_data_root)
    

@payable
@external
def depositByETH(pubkey: Bytes[PUBKEY_LENGTH],
            withdrawal_credentials: Bytes[WITHDRAWAL_CREDENTIALS_LENGTH],
            signature: Bytes[SIGNATURE_LENGTH],
            deposit_data_root: bytes32):
    
    # Avoid overflowing the Merkle tree (and prevent edge case in computing `self.branch`)
    assert self.deposit_count < MAX_DEPOSIT_COUNT
    assert  self.registration_times[msg.sender] == 0, "has deposited"
    self.registration_times[msg.sender] = block.timestamp
    # Check deposit amount
    amount:uint256 = FIXED_DEPOSIT_AMOUNT * (10 ** 18)
    deadline:uint256 = block.timestamp + 10
    Forge(self.forge).ForgeNdaoOutput(amount,msg.value,deadline,msg.sender,self,value=msg.value)
    self._saveInfo(pubkey,withdrawal_credentials,signature,deposit_data_root)
    

@payable
@external
def depositByETHDemo():
    assert self.deposit_count < MAX_DEPOSIT_COUNT
    assert  self.registration_times[msg.sender] == 0, "has deposited"
    self.registration_times[msg.sender] = block.timestamp
    amount:uint256 = FIXED_DEPOSIT_AMOUNT * (10 ** 18)
    deadline:uint256 = block.timestamp + 10
    Forge(self.forge).ForgeNdaoOutput(amount,msg.value,deadline,msg.sender,self,value=msg.value)
    self.deposit_count += 1


@external
def depositByNDAODemo():
    assert self.deposit_count < MAX_DEPOSIT_COUNT
    assert  self.registration_times[msg.sender] == 0, "has deposited"
    self.registration_times[msg.sender] = block.timestamp
    result:bool = NDAOToken(self.ndao).transferFrom(msg.sender,self,FIXED_DEPOSIT_AMOUNT * (10 ** 18))
    assert result
    self.deposit_count += 1

