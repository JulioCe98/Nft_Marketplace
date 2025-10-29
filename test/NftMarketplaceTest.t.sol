// SPDX-License-Identifier: MIT

pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {NftMarketplace} from "../src/NftMarketplace.sol";
import {NFTCollection} from "@NFT_collection_ERC-721/src/NFTCollection.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract NftMarketplaceTest is Test {
    NftMarketplace nftMarketplace;
    NFTCollection nftCollection;

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
    }

    function testSellNft() public {
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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

        //Try to list the same NFT again
        vm.expectRevert("NFT already listed");
        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        vm.stopPrank();
    }

    function testSellNftNotTheOwner() public {
        vm.startPrank(user);

        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        vm.stopPrank();

        vm.startPrank(secondaryUser);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        vm.expectRevert("Not the owner");
        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        vm.stopPrank();
    }

    function testSellNftInvalidPrice() public {
        vm.startPrank(user);

        uint tokenIdToMint = nftCollection.getCurrentTokenId();
        assert(tokenIdToMint == 0);

        nftCollection.mintNft();

        uint currentTokenId = nftCollection.getCurrentTokenId();
        assert(currentTokenId == 1);

        assert(IERC721(address(nftCollection)).ownerOf(tokenIdToMint) == user);

        //Check initial marketplace listed NFTs
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        vm.expectRevert("Invalid price");
        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 0);

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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

        //Execute the cancel sell function
        nftMarketplace.cancelSell(address(nftCollection), tokenIdToMint);

        //Check if the NFT is no longer listed
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        //Check the NFT data is reset
        nft = nftMarketplace.getNft(address(nftCollection), tokenIdToMint);

        assert(nft.seller == address(0));

        vm.stopPrank();
    }

    function testCancelSellNftDoesntExist() public {
        vm.startPrank(user);

        address nftCollectionFake = vm.addr(3);
        uint tokenIdFake = 0;

        vm.expectRevert("NFT doesn't exist");
        nftMarketplace.cancelSell(nftCollectionFake, tokenIdFake);

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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

        vm.stopPrank();

        vm.startPrank(secondaryUser);

        //Check if other user can cancel the sell
        vm.expectRevert("Not the owner");
        nftMarketplace.cancelSell(address(nftCollection), tokenIdToMint);

        vm.stopPrank();
    }

    function testBuyNft() public {
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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, nftPrice);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

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
        nftMarketplace.buyNft{value: nftPrice}(
            address(nftCollection),
            tokenIdToMint
        );

        //Check if the buyer's balance was correctly updated
        uint secondaryUserNewBalance = secondaryUser.balance;
        assert(secondaryUserNewBalance == (etherToDeal - nftPrice));

        //Check if the NFT is no longer listed
        nftsListed = nftMarketplace.nftsListedLength();
        assert(nftsListed == 0);

        vm.stopPrank();

        vm.startPrank(user);

        //Check the seller's NFT listed
        myNftListed = nftMarketplace.getMyNftsListed();
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
        uint nftsListed = nftMarketplace.nftsListedLength();
        assert(nftsListed == 0);

        //Try to buy a non listed NFT
        uint fakeNftPrice = 0.5 ether;
        uint fakeTokenId = 0;

        vm.expectRevert("NFT doesn't exist");
        //Buy the NFT with the other user
        nftMarketplace.buyNft{value: fakeNftPrice}(
            address(nftCollection),
            fakeTokenId
        );

        vm.stopPrank();
    }

    function testBuyNftInvalidAmount() public {
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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, nftPrice);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

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
        nftMarketplace.buyNft{value: nftPrice - 1}(
            address(nftCollection),
            tokenIdToMint
        );

        vm.stopPrank();
    }

    function testBuyNftInvalidEther() public {
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
        uint nftsListed = nftMarketplace.nftsListedLength();
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(nftsListed == 0);
        assert(myNftListed.length == 0);

        uint nftPrice = 1 ether;
        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, nftPrice);

        //Check if the marketplace listed the new NFT
        nftsListed = nftMarketplace.nftsListedLength();
        myNftListed = nftMarketplace.getMyNftsListed();

        assert(nftsListed == 1);
        assert(myNftListed.length == 1);

        //Check if the NFT data is correct
        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);
        assert(nft.nftCollectionAddress == address(nftCollection));
        assert(nft.tokenId == tokenIdToMint);
        assert(nft.price == 1 ether);

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
        nftMarketplace.buyNft{value: 0}(address(nftCollection), tokenIdToMint);

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
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(myNftListed.length == 0);

        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        //Check if the marketplace listed the new NFT
        myNftListed = nftMarketplace.getMyNftsListed();
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
        NftMarketplace.Nft[] memory myNftListed = nftMarketplace
            .getMyNftsListed();

        assert(myNftListed.length == 0);

        nftMarketplace.sellNft(address(nftCollection), tokenIdToMint, 1 ether);

        //Check if the marketplace listed the new NFT
        myNftListed = nftMarketplace.getMyNftsListed();
        assert(myNftListed.length == 1);

        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenIdToMint
        );

        assert(nft.seller == user);

        vm.stopPrank();
    }

    function testGetNftDoesntExist() public view {
        uint tokenId = 0;

        NftMarketplace.Nft memory nft = nftMarketplace.getNft(
            address(nftCollection),
            tokenId
        );

        assert(nft.seller == address(0));
    }
}
