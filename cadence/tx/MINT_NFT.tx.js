const MINT_NFT = `
import NonFungibleToken from 0x631e88ae7f1d7c20
import NFTExample from 0x39d2ec26093f679d //edit this address to your address if you deployed the contract to your account

// This script uses the NFTMinter resource to mint a new NFT
// It must be run with the account that has the minter resource
// stored in NFTExample.MinterStoragePath

transaction(
    description: String,
    image: String,
    name: String,
    series: String
    quantity: UInt64
){

    // local variable for storing the minter reference
    let minter: &NFTExample.NFTMinter

    prepare(signer: AuthAccount) {
        // borrow a reference to the NFTMinter resource in storage
        self.minter = signer.borrow<&NFTExample.NFTMinter>(from: NFTExample.MinterStoragePath)
            ?? panic("Could not borrow a reference to the NFT minter")
    }

    execute {
        // Borrow the recipient's public NFT collection reference
        let receiver = getAccount(0x39d2ec26093f679d) //edit this address to your address if you deployed the contract to your account
            .getCapability(NFTExample.CollectionPublicPath)
            .borrow<&{NonFungibleToken.CollectionPublic}>()
            ?? panic("Could not get receiver reference to the NFT Collection")

        // Mint the NFT and deposit it to the recipient's collection

            var i: UInt64 = 0
            while i < quantity {
                self.minter.mintNFT(
                    recipient: receiver, 
                    description: description,
                    image: image,
                    name: name,
                    series: series,
                )
                i = i + UInt64(1)
                log("Minted an NFT")

            }
    }
}

`

module.exports = {
    MINT_NFT
}