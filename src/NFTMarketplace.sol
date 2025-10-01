// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import {ERC721URIStorage} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract NFTMarketplace is ERC721URIStorage, Ownable {
    uint256 private _tokenIdCounter;
    uint256 public listingFee = 0.025 ether; 
    uint256 private _itemsSold;

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    mapping(uint256 => MarketItem) private idToMarketItem;

    event MarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    constructor() ERC721("NFTMarketplace", "NFTM") Ownable(msg.sender) {}

    function mintNFT(string memory tokenURI, uint256 price) public payable returns (uint256) {
        require(msg.value == listingFee, "Must pay listing fee");

        _tokenIdCounter++;
        uint256 newTokenId = _tokenIdCounter;

        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);

        createMarketItem(newTokenId, price);

        return newTokenId;
    }

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price must be greater than 0");

        idToMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(0)),
            price,
            false
        );

        _transfer(msg.sender, address(this), tokenId);

        emit MarketItemCreated(tokenId, msg.sender, address(0), price, false);
    }

    function buyNFT(uint256 tokenId) public payable {
        MarketItem storage item = idToMarketItem[tokenId];
        require(msg.value == item.price, "Please submit the asking price");
        require(!item.sold, "Item already sold");

        item.owner = payable(msg.sender);
        item.sold = true;
        _itemsSold++;

        _transfer(address(this), msg.sender, tokenId);
        payable(owner()).transfer(listingFee); 
        item.seller.transfer(msg.value); 
    }

    function fetchMarketItems() public view returns (MarketItem[] memory) {
        uint256 itemCount = _tokenIdCounter;
        uint256 unsoldItemCount = itemCount - _itemsSold;
        MarketItem[] memory items = new MarketItem[](unsoldItemCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= itemCount; i++) {
            if (!idToMarketItem[i].sold && idToMarketItem[i].owner == address(0)) {
                items[currentIndex] = idToMarketItem[i];
                currentIndex++;
            }
        }
        return items;
    }

    function updateListingFee(uint256 _newFee) public onlyOwner {
        listingFee = _newFee;
    }
}