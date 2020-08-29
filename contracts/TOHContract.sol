// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;


import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract OwnableDelegateProxy {
    //pass
}


contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}


interface Validator {
    function registration_times(address validator) external view returns(uint256);
}


//主合约
contract TOHContract is ERC721,Ownable {
     //记录每个token对应的质押者和勋章等级
    struct TokenInfo {
        address validator;
        uint256 level;
    }

    //最新版本的openzeppelin的枚举实现已经更改，无法再支持alhpa钱包
    //获取代币图标，自定义提案接口
    /* bytes4(keccak256('getTokenImageSvg(uint256)')) == 0x87d2f48c */
    bytes4 private constant _INTERFACE_ID_TOKEN_IMAGE_SVG = 0x87d2f48c;
    // uint256 constant LEVEL_UNIT = 30 days;
    uint256 constant LEVEL_UNIT = 1 minutes;
    uint256 constant MAX_LEVEL = 12;

    //白名单（代理） opensea使用
    address proxyRegistryAddress;
    //这个是用来处理接入EIP2569自定义接口
    string private svg_template;
    mapping(uint256 => TokenInfo) public tokenInfos;     
    mapping(address => uint256) public withdrawLevel;     //已经领取的奖励等级
    uint256 public  token_id;       //发行的token数量
    Validator public register;   //质押者合约实例
    
    constructor(
        string memory name,
        string memory symbol,
        address _proxyRegistryAddress,
        address register_address
    ) public ERC721(name, symbol) {
        require(_proxyRegistryAddress != address(0), "TOHContract: Zero Address");
        proxyRegistryAddress = _proxyRegistryAddress;
        _registerInterface(_INTERFACE_ID_TOKEN_IMAGE_SVG);
        register = Validator(register_address);
    }

    //计算可以领取的勋章最大等级
    function calMaxLevel(address _validator) public view returns(uint256) {
        uint start = register.registration_times(_validator);
        if(start == 0) {
            return 0;
        }
        uint max_level = block.timestamp.sub(start).div(LEVEL_UNIT);
        if (max_level > MAX_LEVEL) {
            max_level = MAX_LEVEL;
        }
        assert(withdrawLevel[_validator] <= max_level);
        return max_level - withdrawLevel[_validator] ;
    }

    //领取勋章
    function withDrawToken(uint256 _level) external {
        require(_level > 0,"TOHContract: No token");
        uint max_level = calMaxLevel(msg.sender);
        require(_level <= max_level, "TOHContract: Beyond max level");
        withdrawLevel[msg.sender] += _level;
        token_id ++ ;
        _mint(msg.sender,token_id);
        tokenInfos[token_id] = TokenInfo(msg.sender,_level);
    }

    //设置baseURI
    function setBaseURI(string calldata _baseURI) external onlyOwner {
        _setBaseURI(_baseURI);
    }

    //设置勋章图片
    function setSvg(string calldata svg_code) external onlyOwner {
        svg_template = svg_code;
    }

    //获取勋章图标，兼容自定义提案EIP2569接口
    function getTokenImageSvg(uint256 _tokenId) external view returns (string memory){
        require(_exists(_tokenId), "TOHContract: SVG query for nonexistent token");
        return svg_template;
    }

    /**
     * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
     */
    function isApprovedForAll(address owner, address operator)
        public
        override
        view
        returns (bool)
    {
        // Whitelist OpenSea proxy contract for easy trading.
        ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
        if (address(proxyRegistry.proxies(owner)) == operator) {
            return true;
        }
        
        return super.isApprovedForAll(owner, operator);
    }
}
