import NonFungibleToken from 0x631e88ae7f1d7c20
import NFTExample from 0x39d2ec26093f679d //edit this address to your address if you deployed the contract to your account
import MetadataViews from 0x631e88ae7f1d7c20

// This transaction is what an account would run
// to set itself up to receive NFTs

transaction {

    prepare(signer: AuthAccount) {
        // Return early if the account already has a collection
        if signer.borrow<&NFTExample.Collection>(from: NFTExample.CollectionStoragePath) != nil {
            return
        }

        // Create a new empty collection
        let collection <- NFTExample.createEmptyCollection()

        // save it to the account
        signer.save(<-collection, to: NFTExample.CollectionStoragePath)

        // create a public capability for the collection
        signer.link<&{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
            NFTExample.CollectionPublicPath,
            target: NFTExample.CollectionStoragePath
        )
    }

    execute {
      log("Setup account")
    }
}