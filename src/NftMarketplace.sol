// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftMarketplace is Ownable {
    struct Nft {
        address seller;
        address nftCollectionAddress;
        uint tokenId;
        uint price;
    }

    // NftCollectionAddress => tokenId => NFT
    mapping(address => mapping(uint => Nft)) nftsListed;
    //NFTs Listed length
    uint public nftsListedLength = 0;
    //User address => NFTs List
    mapping(address => Nft[]) myNftsListed;
    //Fee Percent
    uint public marketplaceFeePercent = 20;

    modifier nftExists(address nftCollectionAddress_, uint tokenId_) {
        _nftExists(nftCollectionAddress_, tokenId_);
        _;
    }

    event onNftListed(
        address indexed nftCollectionAddress_,
        uint indexed tokenId_,
        uint price_,
        address indexed seller_
    );

    event onCancelSell(
        address indexed nftCollectionAddress_,
        uint indexed tokenId_,
        address indexed seller_
    );

    event onSellNft(
        address indexed nftCollectionAddress_,
        uint indexed tokenId_,
        address seller_,
        address buyer,
        uint price_,
        uint indexed marketplaceEarn_
    );

    constructor() Ownable(msg.sender) {}

    function getMyNftsListed() external view returns (Nft[] memory nfts) {
        nfts = myNftsListed[msg.sender];
    }

    function getNft(
        address nftCollectionAddress_,
        uint tokenId_
    ) external view returns (Nft memory nft) {
        nft = nftsListed[nftCollectionAddress_][tokenId_];
    }

    function sellNft(
        address nftCollectionAddress_,
        uint tokenId_,
        uint price_
    ) external {
        //NFT not added yet
        require(
            nftsListed[nftCollectionAddress_][tokenId_].seller == address(0),
            "NFT already listed"
        );
        //Check if the sender is the owner of the NFT
        address owner = IERC721(nftCollectionAddress_).ownerOf(tokenId_);
        require(msg.sender == owner, "Not the owner");
        //Check the valid price
        require(price_ > 0, "Invalid price");

        Nft memory nftData = Nft({
            seller: msg.sender,
            nftCollectionAddress: nftCollectionAddress_,
            tokenId: tokenId_,
            price: price_
        });

        nftsListed[nftCollectionAddress_][tokenId_] = nftData;
        myNftsListed[msg.sender].push(nftData);
        nftsListedLength++;

        emit onNftListed(nftCollectionAddress_, tokenId_, price_, msg.sender);
    }

    function cancelSell(
        address nftCollectionAddress_,
        uint tokenId_
    ) external nftExists(nftCollectionAddress_, tokenId_) {
        //Check if the sender is the owner of the NFT
        require(
            nftsListed[nftCollectionAddress_][tokenId_].seller == msg.sender,
            "Not the owner"
        );

        _removeNft(nftCollectionAddress_, tokenId_, msg.sender);

        emit onCancelSell(nftCollectionAddress_, tokenId_, msg.sender);
    }

    function buyNft(
        address nftCollectionAddress_,
        uint tokenId_
    ) external payable nftExists(nftCollectionAddress_, tokenId_) {
        //Checks
        require(msg.value > 0, "Invalid ether value");

        Nft memory nftToBuy = nftsListed[nftCollectionAddress_][tokenId_];
        require(msg.value == nftToBuy.price, "Incorrect value sent");

        //Effects
        _removeNft(nftCollectionAddress_, tokenId_, nftToBuy.seller);

        //Interactions
        IERC721(nftCollectionAddress_).safeTransferFrom(
            nftToBuy.seller,
            msg.sender,
            tokenId_
        );

        uint marketFee = (msg.value * marketplaceFeePercent) / 100;
        uint sellerProceeds = msg.value - marketFee;

        (bool result, ) = nftToBuy.seller.call{value: sellerProceeds}("");
        require(result, "Transfer failed");

        emit onSellNft(
            nftCollectionAddress_,
            tokenId_,
            nftToBuy.seller,
            msg.sender,
            nftToBuy.price,
            marketFee
        );
    }

    function changeMarketplaceFee(uint newFee) external onlyOwner {
        marketplaceFeePercent = newFee;
    }

    function _removeNft(
        address nftCollectionAddress_,
        uint tokenId_,
        address seller
    ) internal {
        delete nftsListed[nftCollectionAddress_][tokenId_];
        nftsListedLength--;

        Nft[] storage myNfts = myNftsListed[seller];

        for (uint i = 0; i < myNfts.length; i++) {
            if (myNfts[i].tokenId == tokenId_) {
                myNfts[i] = myNfts[myNfts.length - 1];
                myNfts.pop();
                break;
            }
        }
    }

    function _nftExists(
        address nftCollectionAddress_,
        uint tokenId_
    ) internal view {
        require(
            nftsListed[nftCollectionAddress_][tokenId_].seller != address(0),
            "NFT doesn't exist"
        );
    }
}
