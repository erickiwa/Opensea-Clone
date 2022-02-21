import { useState } from "react";
import { ethers } from "ethers";
import {create as ipfsHttpClient} from 'ipfs-http-client';
import { useRouter } from "next/router";
import Image from "next/image";
import Web3Modal from 'web3modal';

import NFT from '../artifacts/contracts/NFT.sol/NFT.json';
import NFTMarket from '../artifacts/contracts/NFTMarketplace.sol/NFTMarket.json';

const client = ipfsHttpClient("https://ipfs.infura.io:5001/api/v0");

import {
    nftaddress, nftmarketaddress
} from '../config';

export default function CreateItem() {
    const[fileUrl, setFileUrl] = useState(null)
    const[formInput, updateFormInput] = useState({price: '', name: '', description: ''})
    const router = useRouter();

    async function onChange(e) {
        const file = e.target.file[0]
        try{ //tentando fazer um updload de um arquivo
            const added = await client.add(
                file, 
                {
                    progress: (prog) => console.log(`recieved: ${prog}`)
                }
            )
            //salvando o arquivo na url definida
            const url = `https://ips.infura.io/ipfs/${added.path}`
            setFileUrl(url);
        } catch(e) {
            console.log(e);
        }
    }

    async function createItem() {
        const {name, description, price} = formInput; //pegando os valored de um imput
        
        if(!name || !description || !price || !fileUrl) {
            return
        }
        
        const data = JSON.stringify({
            name, description, image: fileUrl
        });
    
        try{
            const added = await client.add(data)
            const url = `https://ipfs.infura.io/ipfs/${added.path}`
            // passando a url para salvar na rede polygon depois do upload do ipfs
            createSale(url)
        } catch(error) {
            console.log(`Erro no upload do seu arquivo`, error)
        }
    }
    
    //listando apra venda
    async function createSale() {
        const web3Modal = new Web3Modal();
        const connection = await web3Modal.connect();
        const provider = new ethers.providers. web3Provider(connection);
    
        //assinando a transação
        let signer = provider.getSigner();
        let contract = ethers.Contract(nftmarketaddress, NFT.abi, signer);
        let transaction = await contract.createToken(url);
        let tx = await transaction.await();
    
        let event = tx.events[0];
        let value = event.args[2];
        let tokenId = value.toNumber();
    
        //pegando a referencia do preço inserido no form
        const price = ethers.utils.parseUnits(formInput.price, 'ether');
        
        contract = ethers.Contract(nftmarketaddress, Market.abi, signer);
    
        //pegando o preço de listagem
        let listingPrice = await contract.getListingPrice()
        listingPrice = listingPrice.toString()
    
        transaction = await contract.createMarketItem()(
            nftaddress, tokenId, price, {value: listingPrice}
        )
    
        await transaction.wait()
        
        router.push('/')

    }

    return (
        <div classnName="flex justfy-center">
            <div className="w-1/2 flex flex-col pb-12">
                <input 
                    placeholder="nome do item"
                    className="mt-8 border rounder p-4"
                    onChange={e => updateFormInput({...formInput, name: e.target.value})}
                    />
                <textarea 
                    placeholder="descrição do item"
                    className="mt-2 border rounded p-4"
                    onChange={e => updateFormInput({ ...formInput, descripton: e.target.value})}
                    />

                <input 
                    placeholder="preço em ETH"
                    className="mt-8 border rounder p-4"
                    onChange={e => updateFormInput({...formInput, name: e.target.value})}
                    />
                    <input 
                        type="file"
                        name= "Asset"
                        className= "my-4"
                        onChange={onChange}    
                    />
                    {
                        fileUrl && (
                            <Image 
                            src={fileUrl} 
                            alt='Nft picture'
                            className="rounded mt-4"
                            widith={350}
                            />
                        )
                    }
                    <button onClick={createItem} 
                    className="font-bold mt-4 bg-pink-500 text-white rounder p-4 shadow-lg"
                    > createNFT </button>
            </div>
        </div>
    )

}

