# 🛍️ NFT Marketplace - Solidity Project

**NFT Marketplace V2** is a decentralized marketplace built in **Solidity** that allows users to list, buy, and cancel NFT sales using **Ether or ERC20 tokens** as payment methods.  

All functionality is secured with access modifiers and internal logic to ensure safe trading between users.

---

## 🚀 Features

- ✅ Buy and sell NFTs using Ether or ERC20 tokens  
- 🔒 Marketplace fee controlled by the contract owner  
- 🧾 Ability to cancel listed NFTs  
- ⚙️ Internal helper functions for modular and secure transactions  
- 🧠 Implemented and tested with **Foundry**

---

## 🧱 Contract Overview

| Concept | Description |
|----------|-------------|
| **Sell NFTs** | Users can list NFTs for sale with a chosen payment token and price |
| **Cancel sale** | Sellers can cancel their listed NFTs anytime |
| **Buy NFTs** | Buyers can purchase NFTs using Ether or supported ERC20 tokens |
| **Marketplace fee** | Owner can adjust the fee charged per sale |
| **Validation** | Uses internal checks to verify that NFTs exist and are properly listed |

---

## ⚙️ Public Functions

| Function | Visibility | Description |
|-----------|-------------|-------------|
| `sellNftV2(address nftCollectionAddress_, uint tokenId_, address paymentTokenAddress_, uint price_)` | `external` | Allows a user to list an NFT for sale, specifying the payment token and price. |
| `cancelSellV2(address nftCollectionAddress_, uint tokenId_)` | `external` | Cancels an active NFT listing. Requires the NFT to exist. |
| `buyNftV2(address nftCollectionAddress_, uint tokenId_)` | `external payable` | Purchases a listed NFT using Ether or ERC20 tokens

 

---

## 🚀 Features

- ✅ ERC721 token support
- ✅ Ether or ERC20 token support for payments too

---

## 🧱 Contract Overview

| Concept | Description |
|---------|-------------|
| Token type | ERC721 (Non-Fungible Token) |
| Tools | Deployed and tested with **Foundry** |

---

## 📦 Solidity Version

```solidity
pragma solidity ^0.8.24;
```

---

# ✨ Author

Project created by **Julio** — deployed as a practice project for **NFT development in Solidity**.
