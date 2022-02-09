//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract NFT is ERC721URIStorage {
    //auto-increment
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    //adress do marketplace de nfts
    address contractAddress;

    constructor(address marketplaceAddress) ERC721("TTcoin", "TTC") {
        contractAddress = marketplaceAddress;
    }

    //função de criação de token
    function createToken(string memory tokenURI) public returns(uint) {
        //cria um novo id para o token que será mintado
        _tokenIds.increment();
        uint newItemId = _tokenIds.current();

        _mint(msg.sender, newItemId); //mint
        _setTokenURI(newItemId, tokenURI); //geração da URI
        setApprovalForAll(contractAddress, true); //garante a permissão no marketplace

        //retorno do novo ID
        return newItemId;
    }
}