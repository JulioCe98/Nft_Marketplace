// SPDX-License-Identifier: MIT

pragma solidity 0.8.24;

import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract NftMarketplace is Ownable {
    struct NftV2 {
        address seller;
        address nftCollectionAddress;
        uint tokenId;
        address paymentTokenAddress;
        uint price;
    }

    // NftCollectionAddress => tokenId => NFT
    mapping(address => mapping(uint => NftV2)) nftsListedV2;
    //NFTs Listed length
    uint public nftsListedV2Length = 0;
    //User address => NFTs List
    mapping(address => NftV2[]) myNftsV2Listed;
    //Fee Percent
    uint public marketplaceFeePercent = 20;

    modifier nftV2Exists(address nftCollectionAddress_, uint tokenId_) {
        _nftV2Exists(nftCollectionAddress_, tokenId_);
        _;
    }

    modifier validateAmount(uint amount_) {
        _isValidAmount(amount_);
        _;
    }

    event onNftV2Listed(
        address indexed nftCollectionAddress_,
        uint indexed tokenId_,
        address paymentTokenAddress_,
        uint price_,
        address indexed seller_
    );

    event onCancelSell(
        address indexed nftCollectionAddress_,
        uint indexed tokenId_,
        address indexed seller_
    );

    event onSellNftV2(
        address indexed nftCollectionAddress_,
        uint indexed tokenId_,
        address seller_,
        address buyer,
        uint price_,
        uint indexed marketplaceEarn_,
        address paymentTokenAddress_
    );

    constructor() Ownable(msg.sender) {}

    function getMyNftsListedV2() external view returns (NftV2[] memory nfts) {
        nfts = myNftsV2Listed[msg.sender];
    }

    function getNftV2(
        address nftCollectionAddress_,
        uint tokenId_
    ) external view returns (NftV2 memory nft) {
        nft = nftsListedV2[nftCollectionAddress_][tokenId_];
    }

    function sellNftV2(
        address nftCollectionAddress_,
        uint tokenId_,
        address paymentTokenAddress_,
        uint price_
    ) external {
        //NFT not added yet
        require(
            nftsListedV2[nftCollectionAddress_][tokenId_].seller == address(0),
            "NFT already listed"
        );
        //Check if the sender is the owner of the NFT
        address owner = IERC721(nftCollectionAddress_).ownerOf(tokenId_);
        require(msg.sender == owner, "Not the owner");
        //Check the valid price
        require(price_ > 0, "Invalid price");

        NftV2 memory nftData = NftV2({
            seller: msg.sender,
            nftCollectionAddress: nftCollectionAddress_,
            tokenId: tokenId_,
            paymentTokenAddress: paymentTokenAddress_,
            price: price_
        });

        nftsListedV2[nftCollectionAddress_][tokenId_] = nftData;
        myNftsV2Listed[msg.sender].push(nftData);
        nftsListedV2Length++;

        emit onNftV2Listed(
            nftCollectionAddress_,
            tokenId_,
            paymentTokenAddress_,
            price_,
            msg.sender
        );
    }

    function cancelSellV2(
        address nftCollectionAddress_,
        uint tokenId_
    ) external nftV2Exists(nftCollectionAddress_, tokenId_) {
        //Check if the sender is the owner of the NFT
        require(
            nftsListedV2[nftCollectionAddress_][tokenId_].seller == msg.sender,
            "Not the owner"
        );

        _removeNftV2(nftCollectionAddress_, tokenId_, msg.sender);

        emit onCancelSell(nftCollectionAddress_, tokenId_, msg.sender);
    }

    function buyNftV2(
        address nftCollectionAddress_,
        uint tokenId_
    ) external payable nftV2Exists(nftCollectionAddress_, tokenId_) {
        NftV2 memory nftToBuy = this.getNftV2(nftCollectionAddress_, tokenId_);

        address paymentTokenAddress = nftToBuy.paymentTokenAddress;

        if (paymentTokenAddress == address(0)) {
            //Pay with ether
            _buyWithEther(nftCollectionAddress_, tokenId_);
        } else {
            //Pay with ERC20 tokens
            _buyWithToken(nftCollectionAddress_, tokenId_);
        }
    }

    function _buyWithEther(
        address nftCollectionAddress_,
        uint tokenId_
    ) internal {
        //Checks
        require(msg.value > 0, "Invalid ether value");

        NftV2 memory nftToBuy = this.getNftV2(nftCollectionAddress_, tokenId_);
        require(msg.value == nftToBuy.price, "Incorrect value sent");

        //Effects
        _removeNftV2(nftCollectionAddress_, tokenId_, nftToBuy.seller);

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

        emit onSellNftV2(
            nftCollectionAddress_,
            tokenId_,
            nftToBuy.seller,
            msg.sender,
            nftToBuy.price,
            marketFee,
            address(0)
        );
    }

    function _buyWithToken(
        address nftCollectionAddress_,
        uint tokenId_
    ) internal {
        //Checks
        require(msg.value == 0, "Don't send ether with this payment method");

        NftV2 memory nftToBuy = this.getNftV2(nftCollectionAddress_, tokenId_);

        address paymentTokenAddress = nftToBuy.paymentTokenAddress;
        uint nftPrice = nftToBuy.price;

        uint buyerBalance = IERC20(paymentTokenAddress).balanceOf(msg.sender);
        require(buyerBalance >= nftPrice, "Insufficient balance");

        //Effects
        _removeNftV2(nftCollectionAddress_, tokenId_, nftToBuy.seller);

        bool transferFromBuyerResult = IERC20(paymentTokenAddress).transferFrom(
            msg.sender,
            address(this),
            nftPrice
        );

        require(transferFromBuyerResult, "Transfer failed");

        //Interactions
        IERC721(nftCollectionAddress_).safeTransferFrom(
            nftToBuy.seller,
            msg.sender,
            tokenId_
        );

        uint marketFee = (nftPrice * marketplaceFeePercent) / 100;
        uint sellerProceeds = nftPrice - marketFee;

        bool transferToSellerResult = IERC20(paymentTokenAddress).transferFrom(
            address(this),
            nftToBuy.seller,
            sellerProceeds
        );

        require(transferToSellerResult, "Transfer failed");

        emit onSellNftV2(
            nftCollectionAddress_,
            tokenId_,
            nftToBuy.seller,
            msg.sender,
            nftToBuy.price,
            marketFee,
            paymentTokenAddress
        );
    }

    function changeMarketplaceFee(uint newFee) external onlyOwner {
        marketplaceFeePercent = newFee;
    }

    receive() external payable {}

    function withdrawEther(
        uint amount_
    ) external onlyOwner validateAmount(amount_) {
        (bool transactionResult, ) = msg.sender.call{value: amount_}("");
        require(transactionResult, "Withdraw failed");
    }

    function withdrawErc20(
        address tokenAddress_,
        uint amount_
    ) external onlyOwner validateAmount(amount_) {
        bool result = IERC20(tokenAddress_).transfer(msg.sender, amount_);
        require(result, "Withdraw failed");
    }

    function _removeNftV2(
        address nftCollectionAddress_,
        uint tokenId_,
        address seller
    ) internal {
        delete nftsListedV2[nftCollectionAddress_][tokenId_];
        nftsListedV2Length--;

        NftV2[] storage myNfts = myNftsV2Listed[seller];

        for (uint i = 0; i < myNfts.length; i++) {
            if (myNfts[i].tokenId == tokenId_) {
                myNfts[i] = myNfts[myNfts.length - 1];
                myNfts.pop();
                break;
            }
        }
    }

    function _nftV2Exists(
        address nftCollectionAddress_,
        uint tokenId_
    ) internal view {
        require(
            nftsListedV2[nftCollectionAddress_][tokenId_].seller != address(0),
            "NFT doesn't exist"
        );
    }

    function _isValidAmount(uint amount_) internal pure {
        require(amount_ > 0, "Invalid amount");
    }
}
