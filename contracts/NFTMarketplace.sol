//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
//prevenção de re-entrancy attacks
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";


contract NFTMarket is ReentrancyGuard {
    using Counters for Counters.Counter;
    Counters.Counter private _itemIds;
    Counters.Counter private _itemsSold; //total de items vendidos

    address payable owner; //dono do contrato
    //preço a ser pago para colocar um item a venda
    uint256 listingPrice = 0.025 ether;

    constructor() {
        owner = payable(msg.sender);
    }

    struct MarketItem {
        uint itemId;
        address nftContract;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    //acesso aos valores do item no market pelo id
    mapping(uint256 => MarketItem) private idMarketItem;

    //log da venda de um item
    event MarketItemCreated (
        uint indexed itemId,
        address indexed nftContract,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    // função para puxar o preço para listagem
    function getListingPrice() public view returns(uint256) {
        return listingPrice;
    }

    function setListingPrice(uint _price) public returns(uint) {
        if(msg.sender == address(this)) {
            listingPrice = _price;
        }

        return listingPrice;
    }

    
    //criando o item no market
    function createMarketItem(address nftContract, uint256 tokenId, uint256 price) public payable nonReentrant {
        require(price > 0, "O preco nao pode ser 0");
        require(msg.value == listingPrice, "O preco precisa ser iguakl ao ListingPrice");

        _itemIds.increment(); //adiciona em 1 o total de items criados
        uint256 itemId = _itemIds.current();

        idMarketItem[itemId] = MarketItem(
            itemId, 
            nftContract, 
            tokenId, 
            payable(msg.sender), //address do vendedor
            payable(address(0)), //por enquanto não tem um dono então deixei vazio
            price, 
            false
        );

        //transferindo a propriedade do contrato(nft)
        IERC721(nftContract).transferFrom(msg.sender, address(this), tokenId);
        
        //log da transação
        emit MarketItemCreated(
            itemId, 
            nftContract, 
            tokenId, 
            msg.sender, 
            address(0), 
            price, 
            false);
    }

    function createMarketSale(address nftContract, uint256 itemId) public payable nonReentrant{
        uint price = idMarketItem[itemId].price;
        uint tokenId = idMarketItem[itemId].tokenId;

        require(msg.value == price, "Insira o valor correto para completar a transacao");
        
        //pagando ao vendedor
        idMarketItem[itemId].seller.transfer(msg.value);

        IERC721(nftContract).transferFrom(address(this), msg.sender, tokenId);

        idMarketItem[itemId].owner = payable(msg.sender); //marca o comprador como novo dono
        idMarketItem[itemId].sold = true; //marca que o item foi vendido
        _itemsSold.increment(); //incrementa o total de itens vendidos
        payable(owner).transfer(listingPrice); //paga ao dono do contrato o preço de listagem
    }

    //numero total de items nque não foram vendidos
    function fetchMarketItems() public view returns(MarketItem[] memory) {
        uint itemCount = _itemIds.current(); //numero total de items criados na plataforma
        uint unSoldItemCount = _itemIds.current() - _itemsSold.current(); //total de items vendidos, retirando os que apenas foram mintados da conta.
        uint currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        //loop em todos os items criados
        for(uint i = 0; i < itemCount; i++) {
            //checando se o item não foi vendido
            if(idMarketItem[i+1].owner == address(0)) {
                uint currentId = idMarketItem[i + 1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    //lista os nfts de quem chamar essa função
    function fetchMyNFTs() public view returns(MarketItem[] memory) {
        //pegando todos os items criados
        uint totalItemCount = _itemIds.current();

        uint itemCount = 0;
        uint currentIndex = 0;

        for(uint i = 0; i < totalItemCount; i++){
            //pegando apenas os items possuiidos por quem fez a interação
            if(idMarketItem[i+1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for(uint i = 0; i < totalItemCount; i++){
            if(idMarketItem[i+1].seller == msg.sender){
                uint currentId = idMarketItem[i+1].itemId;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex +=1;
            }
        }

        return items;
    }
}