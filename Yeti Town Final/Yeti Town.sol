// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/MerkleProof.sol";

contract YetiTown is ERC721Enumerable, Ownable 
{
    using Strings for string;

    uint public constant MAX_TOKENS = 4444;
    uint public PRESALE_LIMIT = 4444;
    uint public presaleTokensSold = 0;
    uint public constant NUMBER_RESERVED_TOKENS = 200;
    uint256 public PRICE = 0.057 ether; //57000000000000000
    uint public perAddressLimit = 6;
    
    bool public saleIsActive = false;
    bool public preSaleIsActive = false;
    bool public whitelist = true;
    bool public revealed = false;

    uint public reservedTokensMinted = 0;
    string private _baseTokenURI;
    string public notRevealedUri;
    bytes32 root;
    mapping(address => uint) public addressMintedBalance;

    address payable private devguy = payable(0x0F7961EE81B7cB2B859157E9c0D7b1A1D9D35A5D);

    constructor() ERC721("Yeti Town", "YT") {}

    function mintToken(uint256 amount, bytes32[] memory proof) external payable
    {
        require(!whitelist || verify(proof), "Address not whitelisted");
        require(msg.sender == tx.origin, "No transaction from smart contracts!");
        require(preSaleIsActive || saleIsActive, "Sale must be active to mint");
        require(amount > 0 && amount <= 3, "Max 3 NFTs per transaction");
        require(!preSaleIsActive || presaleTokensSold + amount <= PRESALE_LIMIT, "Purchase would exceed max supply");
        require(totalSupply() + amount <= MAX_TOKENS - (NUMBER_RESERVED_TOKENS - reservedTokensMinted), "Purchase would exceed max supply");
        require(msg.value >= PRICE * amount, "Not enough ETH for transaction");
        require(addressMintedBalance[msg.sender] + amount <= perAddressLimit, "Max NFT per address exceeded");
        
        for (uint i = 0; i < amount; i++) 
        {
            addressMintedBalance[msg.sender]++;
            _safeMint(msg.sender, totalSupply() + 1);
        }

        if (preSaleIsActive) presaleTokensSold++;
    }

    //case ethereum does something crazy
    function setPrice(uint256 newPrice) external onlyOwner 
    {
        PRICE = newPrice;
    }

    function setPresaleLimit(uint newLimit) external onlyOwner 
    {
        PRESALE_LIMIT = newLimit;
    }

    function setPerAddressLimit(uint newLimit) external onlyOwner 
    {
        perAddressLimit = newLimit;
    }

    function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function reveal() public onlyOwner {
        revealed = true;
    }

    function flipSaleState() external onlyOwner 
    {
        saleIsActive = !saleIsActive;
    }

    function flipPreSaleState() external onlyOwner 
    {
        preSaleIsActive = !preSaleIsActive;
    }

    function flipWhitelistingState() external onlyOwner 
    {
        whitelist = !whitelist;
    }

    function mintReservedTokens(address to, uint256 amount) external onlyOwner 
    {
        require(reservedTokensMinted + amount <= NUMBER_RESERVED_TOKENS, "This amount is more than max allowed");

        for (uint i = 0; i < amount; i++) 
        {
            _safeMint(to, totalSupply() + 1);
            reservedTokensMinted++;
        }
    }
    
    function withdraw() external 
    {
        require(msg.sender == devguy || msg.sender == owner(), "Invalid sender");
        (bool success, ) = devguy.call{value: address(this).balance / 1000 * 75}(""); //7.5%
        (bool success2, ) = owner().call{value: address(this).balance}("");
        require(success, "Transfer 1 failed");
        require(success2, "Transfer 2 failed");
    }

    function setRoot(bytes32 _root) external onlyOwner
    {
        root = _root;
    }

    function verify(bytes32[] memory proof) internal view returns (bool) 
    {
        bytes32 leaf = keccak256(abi.encodePacked(msg.sender));
        return MerkleProof.verify(proof, root, leaf);
    }
    
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }
    
    function supportsInterface(bytes4 interfaceId) public view
        override(ERC721Enumerable) returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
    
    ////
    //URI management part
    ////
    
    function _setBaseURI(string memory baseURI) internal virtual {
        _baseTokenURI = baseURI;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }
    
    function setBaseURI(string memory baseURI) external onlyOwner {
        _setBaseURI(baseURI);
    }
  
    function tokenURI(uint256 tokenId) public view virtual override returns (string memory)
    {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");

        if(revealed == false) 
        {
            return notRevealedUri;
        }

        string memory _tokenURI = super.tokenURI(tokenId);
        return bytes(_tokenURI).length > 0 ? string(abi.encodePacked(_tokenURI, ".json")) : "";
    }
}