const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("NFTMarket", function () {
  it("deve criar e executar vendas no market", async function () {
    const Market = await ethers.getContractFactory("NFTMarket");
    const market = await Market.deploy();
    await market.deployed(); //deploy do NFTMarketplace
    const marketAddress = market.address;

    const NFT = await ethers.getContractFactory("NFT");
    const nft = await NFT.deploy(marketAddress);
    await nft.deployed(); //deploy do NFT
    const nftContractAddress = nft.address;

    //puxando p reço de listagem
    let listingPrice = await market.getListingPrice();
    listingPrice = listingPrice.toString();

    //preço que queremos usar para vender nosso NFT
    const auctionPrice = ethers.utils.parseUnits("100", "ether");

    
    //criando duas tokens de testes
    await nft.createToken("https://mytokenlocation.com");
    await nft.createToken("https://mytokenlocation2.com");

    //criando 2 nfts de testes
    await market.createMarketItem(nftContractAddress, 1 , auctionPrice, {value: listingPrice});
    await market.createMarketItem(nftContractAddress, 2 , auctionPrice, {value: listingPrice});

    const [_, buyerAddress] = await ethers.getSigners();

    await market.connect(buyerAddress).createMarketSale(nftContractAddress, 1, {value: auctionPrice});

    //buscando items no market
    let items = await market.fetchMarketItems();

    items = await Promise.all(items.map(async i => {
      const tokenUri = await nft.tokenURI(i.tokenId)
      let item = {
        price: i.price.toString(), 
        tokenId: i.tokenId.toString(), 
        seller: i.seller, 
        tokenUri
      }

      return item;
    }))
    console.log('items: ', items);
  });
});
