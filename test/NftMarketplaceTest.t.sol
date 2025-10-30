// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {NftMarketplace} from "../src/NftMarketplace.sol";
import {NFTCollection} from "@NFT_collection_ERC-721/src/NFTCollection.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockUsdt is ERC20 {
    constructor(
        string memory name_,
        string memory symbol_
    ) ERC20(name_, symbol_) {}

    function mint(uint amount_) external {
        _mint(msg.sender, amount_);
    }
}

contract NftMarketplaceTest is Test {
    NftMarketplace nftMarketplace;
    NFTCollection nftCollection;
    MockUsdt usdtMock;

    string name = "NFT Collection Test";
    string symbol = "NFTCT";
    uint nftCollectionMaxSupply = 2;
    string baseURI = "ipfs://xyz/";

    address user = vm.addr(1);
    address secondaryUser = vm.addr(2);

    function setUp() public {
        nftMarketplace = new NftMarketplace();
        nftCollection = new NFTCollection(
            name,
            symbol,
            nftCollectionMaxSupply,
            baseURI
        );
        usdtMock = new MockUsdt("USD", "USDT");
    }

    function testSellNftV2WithEther() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(0));
        assert(nft.price == nftPrice);

        vm.stopPrank();
    }

    function testSellNftV2WithErc20() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 4000;

        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(usdtMock),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(usdtMock));
        assert(nft.price == nftPrice);

        vm.stopPrank();
    }

    function testSellNftAlreadyListed() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 4000;

        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(usdtMock),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(usdtMock));
        assert(nft.price == nftPrice);

        //Try to list the same NFT again
        vm.expectRevert("NFT already listed");
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        vm.stopPrank();
    }

    function testSellNftNotTheOwner() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        vm.stopPrank();

        //Mock the second user
        vm.startPrank(secondaryUser);

        uint nftPrice = 4000;

        //Try to sell the NFT of other user
        vm.expectRevert("Not the owner");
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        vm.stopPrank();
    }

    function testSellNftInvalidEtherPrice() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 0;

        vm.expectRevert("Invalid price");
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        vm.stopPrank();
    }

    function testSellNftInvalidErc20Price() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 0;

        vm.expectRevert("Invalid price");
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(usdtMock),
            nftPrice
        );

        vm.stopPrank();
    }

    function testCancelSellNft() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);

        //Execute the cancel sell function
        nftMarketplace.cancelSellV2(address(nftCollection), tokenIdToMint);

        //Check if the NFT is no longer listed
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        //Check the NFT data is reset
        nft = nftMarketplace.getNftV2(address(nftCollection), tokenIdToMint);

        assert(nft.seller == address(0));

        vm.stopPrank();
    }

    function testCancelSellNftDoesntExist() public {
        vm.startPrank(user);

        address nftCollectionFake = vm.addr(3);
        uint tokenIdFake = 0;

        vm.expectRevert("NFT doesn't exist");
        nftMarketplace.cancelSellV2(nftCollectionFake, tokenIdFake);

        vm.stopPrank();
    }

    function testCancelSellNotOwner() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);

        vm.stopPrank();

        //Mock the second user
        vm.startPrank(secondaryUser);

        //Check if second user can cancel the sell
        vm.expectRevert("Not the owner");
        nftMarketplace.cancelSellV2(address(nftCollection), tokenIdToMint);

        vm.stopPrank();
    }

    function testChangeMarketplaceFee() public {
        uint initialFee = nftMarketplace.marketplaceFeePercent();

        uint newFee = 10;
        nftMarketplace.changeMarketplaceFee(newFee);

        uint currentFee = nftMarketplace.marketplaceFeePercent();
        assert(currentFee == newFee);
        assert(currentFee != initialFee);
    }

    function testCantChangeMarketplaceFee() public {
        vm.startPrank(user);

        uint newFee = 10;

        vm.expectRevert();
        nftMarketplace.changeMarketplaceFee(newFee);

        vm.stopPrank();
    }

    function testGetMyNftsListed() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        myNftListed = nftMarketplace.getMyNftsListedV2();
        assert(myNftListed.length == 1);

        vm.stopPrank();
    }

    function testGetNftExist() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        myNftListed = nftMarketplace.getMyNftsListedV2();
        assert(myNftListed.length == 1);

        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);

        vm.stopPrank();
    }

    function testGetNftDoesntExist() public view {
        uint tokenId = 0;

        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenId
        );

        assert(nft.seller == address(0));
    }

    function testBuyNftWithEther() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(0));
        assert(nft.price == nftPrice);

        //Approve the marketplace to transfer the NFT
        IERC721(address(nftCollection)).approve(
            address(nftMarketplace),
            tokenIdToMint
        );

        vm.stopPrank();

        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        //Deal some ether to the buyer
        uint etherToDeal = 2 ether;
        vm.deal(secondaryUser, etherToDeal);

        //Check if the ether was correctly sent to the contract
        uint secondaryUserInitialBalance = secondaryUser.balance;
        assert(secondaryUserInitialBalance == etherToDeal);

        //Buy the NFT with the other user
        nftMarketplace.buyNftV2{value: nftPrice}(
            address(nftCollection),
            tokenIdToMint
        );

        //Check if the buyer's balance was correctly updated
        uint secondaryUserNewBalance = secondaryUser.balance;
        assert(secondaryUserNewBalance == (etherToDeal - nftPrice));

        //Check if the NFT is no longer listed
        nftsListed = nftMarketplace.nftsListedV2Length();
        assert(nftsListed == 0);

        vm.stopPrank();

        vm.startPrank(user);

        //Check the seller's NFT listed
        myNftListed = nftMarketplace.getMyNftsListedV2();
        assert(myNftListed.length == 0);

        vm.stopPrank();

        //Check the new NFT owner
        address newOwner = IERC721(address(nftCollection)).ownerOf(
            tokenIdToMint
        );
        assert(newOwner == secondaryUser);

        //Check the marketplace fee
        uint marketFee = (nftPrice * nftMarketplace.marketplaceFeePercent()) /
            100;
        //Check if the marketplace received the fee
        uint marketBalance = address(nftMarketplace).balance;
        assert(marketBalance == marketFee);

        //Check if the seller received the correct amount
        uint newSellerBalance = user.balance;
        assert(newSellerBalance == (nftPrice - marketFee));
    }

    function testBuyNftWithErc20() public {
        //Mock the Buyer
        vm.startPrank(secondaryUser);
        uint toMint = 5000;
        usdtMock.mint(toMint);
        vm.stopPrank();

        uint userBalance = IERC20(address(usdtMock)).balanceOf(secondaryUser);
        assert(userBalance == toMint);

        vm.startPrank(user);
        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPriceInUsdtMock = 2500;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(usdtMock),
            nftPriceInUsdtMock
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(usdtMock));
        assert(nft.price == nftPriceInUsdtMock);

        //Approve the marketplace to transfer the NFT
        IERC721(address(nftCollection)).approve(
            address(nftMarketplace),
            tokenIdToMint
        );
        vm.stopPrank();

        //Mock the marketplace
        vm.startPrank(address(nftMarketplace));
        //Check the marketplace fee
        uint marketFee = (nftPriceInUsdtMock *
            nftMarketplace.marketplaceFeePercent()) / 100;
        uint sellerEarn = nftPriceInUsdtMock - marketFee;

        IERC20(usdtMock).approve(address(nftMarketplace), sellerEarn);
        vm.stopPrank();

        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        IERC20(usdtMock).approve(address(nftMarketplace), nftPriceInUsdtMock);

        //Deal some ether to the buyer
        //Buy the NFT with the other user
        nftMarketplace.buyNftV2(address(nftCollection), tokenIdToMint);

        //Check if the NFT is no longer listed
        nftsListed = nftMarketplace.nftsListedV2Length();
        assert(nftsListed == 0);

        vm.stopPrank();

        vm.startPrank(user);
        //Check the seller's NFT listed
        myNftListed = nftMarketplace.getMyNftsListedV2();
        assert(myNftListed.length == 0);
        vm.stopPrank();

        //Check the new NFT owner
        address newOwner = IERC721(address(nftCollection)).ownerOf(
            tokenIdToMint
        );
        assert(newOwner == secondaryUser);

        //Check if the marketplace received the fee
        uint marketErc20Balance = IERC20(address(usdtMock)).balanceOf(
            address(nftMarketplace)
        );
        assert(marketErc20Balance == marketFee);

        //Check if the seller received the correct amount
        uint newSellerErc20Balance = IERC20(address(usdtMock)).balanceOf(user);
        assert(newSellerErc20Balance == sellerEarn);
    }

    function testBuyNftDoesntExist() public {
        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        //Deal some ether to the buyer
        uint etherToDeal = 2 ether;
        vm.deal(secondaryUser, etherToDeal);

        //Check if the ether was correctly sent to the contract
        uint secondaryUserInitialBalance = secondaryUser.balance;
        assert(secondaryUserInitialBalance == etherToDeal);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        assert(nftsListed == 0);

        //Try to buy a non listed NFT
        uint fakeNftPrice = 0.5 ether;
        uint fakeTokenId = 0;

        vm.expectRevert("NFT doesn't exist");
        //Buy the NFT with the other user
        nftMarketplace.buyNftV2{value: fakeNftPrice}(
            address(nftCollection),
            fakeTokenId
        );

        vm.stopPrank();
    }

    function testBuyNftInvalidEtherAmount() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(0));
        assert(nft.price == nftPrice);

        //Approve the marketplace to transfer the NFT
        IERC721(address(nftCollection)).approve(
            address(nftMarketplace),
            tokenIdToMint
        );

        vm.stopPrank();

        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        //Deal some ether to the buyer
        uint etherToDeal = 2 ether;
        vm.deal(secondaryUser, etherToDeal);

        //Check if the ether was correctly sent to the contract
        uint secondaryUserInitialBalance = secondaryUser.balance;
        assert(secondaryUserInitialBalance == etherToDeal);

        vm.expectRevert("Incorrect value sent");
        //Buy the NFT with the other user but invalid amount
        nftMarketplace.buyNftV2{value: nftPrice - 1}(
            address(nftCollection),
            tokenIdToMint
        );

        vm.stopPrank();
    }

    function testBuyNftNoErc20Balance() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1000;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(usdtMock),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(usdtMock));
        assert(nft.price == nftPrice);

        //Approve the marketplace to transfer the NFT
        IERC721(address(nftCollection)).approve(
            address(nftMarketplace),
            tokenIdToMint
        );

        vm.stopPrank();

        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        vm.expectRevert("Insufficient balance");
        //Buy the NFT with the other user but invalid amount
        nftMarketplace.buyNftV2(address(nftCollection), tokenIdToMint);

        vm.stopPrank();
    }

    function testBuyNftErc20BalanceAndSendEtherToo() public {
        //Mock the Buyer
        vm.startPrank(secondaryUser);
        uint toMint = 5000;
        usdtMock.mint(toMint);
        vm.stopPrank();

        uint userBalance = IERC20(address(usdtMock)).balanceOf(secondaryUser);
        assert(userBalance == toMint);

        //Deal some ether to the buyer
        uint etherToDeal = 2 ether;
        vm.deal(secondaryUser, etherToDeal);

        //Check if the ether was correctly sent to the contract
        uint secondaryUserInitialBalance = secondaryUser.balance;
        assert(secondaryUserInitialBalance == etherToDeal);

        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1000;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(usdtMock),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(usdtMock));
        assert(nft.price == nftPrice);

        //Approve the marketplace to transfer the NFT
        IERC721(address(nftCollection)).approve(
            address(nftMarketplace),
            tokenIdToMint
        );

        vm.stopPrank();

        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        vm.expectRevert("Don't send ether with this payment method");
        //Buy the NFT with the other user but invalid amount
        nftMarketplace.buyNftV2{value: etherToDeal - 1}(
            address(nftCollection),
            tokenIdToMint
        );

        vm.stopPrank();
    }

    function testBuyNftSendZeroEther() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedV2Length();
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedV2Length();
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(0));
        assert(nft.price == nftPrice);

        //Approve the marketplace to transfer the NFT
        IERC721(address(nftCollection)).approve(
            address(nftMarketplace),
            tokenIdToMint
        );

        vm.stopPrank();

        //Mock to the user who will buy the NFT
        vm.startPrank(secondaryUser);
        //Deal some ether to the buyer
        uint etherToDeal = 2 ether;
        vm.deal(secondaryUser, etherToDeal);

        //Check if the ether was correctly sent to the contract
        uint secondaryUserInitialBalance = secondaryUser.balance;
        assert(secondaryUserInitialBalance == etherToDeal);

        vm.expectRevert("Invalid ether value");
        //Buy the NFT with the other user but invalid amount
        nftMarketplace.buyNftV2{value: 0}(
            address(nftCollection),
            tokenIdToMint
        );

        vm.stopPrank();
    }

    function testGetMyNftsListedV2() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        myNftListed = nftMarketplace.getMyNftsListedV2();

        assert(myNftListed.length == 1);
    }

    function testGetNftV2() public {
        vm.startPrank(user);

        //First ID to mint
        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        //Check owner of minted NFT
        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        NftMarketplace.NftV2[] memory myNftListed = nftMarketplace
            .getMyNftsListedV2();

        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNftV2(
            address(nftCollection),
            tokenIdToMint,
            address(0),
            nftPrice
        );

        //Check if the marketplace listed the new NFT
        myNftListed = nftMarketplace.getMyNftsListedV2();
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.NftV2 memory nft = nftMarketplace.getNftV2(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.paymentTokenAddress == address(0));
        assert(nft.price == nftPrice);
    }
}
