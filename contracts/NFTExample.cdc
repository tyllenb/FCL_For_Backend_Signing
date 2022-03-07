import NonFungibleToken from 0x631e88ae7f1d7c20
import MetadataViews from 0x631e88ae7f1d7c20

pub contract NFTExample: NonFungibleToken {

    // Events
    //
    pub event ContractInitialized()
    pub event Withdraw(id: UInt64, from: Address?)
    pub event Deposit(id: UInt64, to: Address?)
    pub event Minted(id: UInt64, name: String)

    // Named Paths
    //
    pub let CollectionStoragePath: StoragePath
    pub let CollectionPublicPath: PublicPath
    pub let MinterStoragePath: StoragePath

    // totalSupply
    // The total number of NFTExample that have been minted
    //
    pub var totalSupply: UInt64
    
    // A NFTExample as an NFT
    //
    pub resource NFT: NonFungibleToken.INFT, MetadataViews.Resolver {

        pub let id: UInt64
        pub let description: String
        pub let image: String
        pub let name: String
        pub let series: String
        


        init(
            id: UInt64, 
            description: String,
            image: String,
            name: String,
            series: String,
            ) {
            self.id = id
            self.description = description
            self.image = image
            self.name = name
            self.series = series
        }

        pub fun getViews(): [Type] {
            return [
                Type<MetadataViews.Display>()
            ]
        }

        pub fun resolveView(_ view: Type): AnyStruct? {
            switch view {
                case Type<MetadataViews.Display>():
                    return MetadataViews.Display(
                        name: self.name,
                        description: self.description,
                        thumbnail: MetadataViews.IPFSFile(
                            cid: self.image, 
                            path: "sm.png"
                        )
                    )
            }

            return nil
        }
    }

    // This is the interface that users can cast their NFTExample Collection as
    // to allow others to deposit NFTExample into their Collection. It also allows for reading
    // the details of NFTExample in the Collection.
    pub resource interface NFTExampleCollectionPublic {
        pub fun deposit(token: @NonFungibleToken.NFT)
        pub fun getIDs(): [UInt64]
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT
        pub fun borrowNFTExample(id: UInt64): &NFTExample.NFT? {
            // If the result isn't nil, the id of the returned reference
            // should be the same as the argument to the function
            post {
                (result == nil) || (result?.id == id):
                    "Cannot borrow NFTExample reference: The ID of the returned reference is incorrect"
            }
        }
    }

    // Collection
    // A collection of NFTExample NFTs owned by an account
    //
    pub resource Collection: NFTExampleCollectionPublic, NonFungibleToken.Provider, NonFungibleToken.Receiver, NonFungibleToken.CollectionPublic {
        // dictionary of NFT conforming tokens
        // NFT is a resource type with an `UInt64` ID field
        //
        pub var ownedNFTs: @{UInt64: NonFungibleToken.NFT}

        // withdraw
        // Removes an NFT from the collection and moves it to the caller
        //
        pub fun withdraw(withdrawID: UInt64): @NonFungibleToken.NFT {
            let token <- self.ownedNFTs.remove(key: withdrawID) ?? panic("missing NFT")

            emit Withdraw(id: token.id, from: self.owner?.address)

            return <-token
        }

        // deposit
        // Takes a NFT and adds it to the collections dictionary
        // and adds the ID to the id array
        //
        pub fun deposit(token: @NonFungibleToken.NFT) {
            let token <- token as! @NFTExample.NFT

            let id: UInt64 = token.id

            // add the new token to the dictionary which removes the old one
            let oldToken <- self.ownedNFTs[id] <- token

            emit Deposit(id: id, to: self.owner?.address)

            destroy oldToken
        }

        // getIDs
        // Returns an array of the IDs that are in the collection
        //
        pub fun getIDs(): [UInt64] {
            return self.ownedNFTs.keys
        }

        // borrowNFT
        // Gets a reference to an NFT in the collection
        // so that the caller can read its metadata and call its methods
        //
        pub fun borrowNFT(id: UInt64): &NonFungibleToken.NFT {
            return &self.ownedNFTs[id] as &NonFungibleToken.NFT
        }

        // borrowNFTExample
        // Gets a reference to an NFT in the collection as a NFTExample,
        // exposing all of its fields (including the typeID & rarityID).
        // This is safe as there are no functions that can be called on the NFTExample.
        //
        pub fun borrowNFTExample(id: UInt64): &NFTExample.NFT? {
            if self.ownedNFTs[id] != nil {
                let ref = &self.ownedNFTs[id] as auth &NonFungibleToken.NFT
                return ref as! &NFTExample.NFT
            } else {
                return nil
            }
        }

        // destructor
        destroy() {
            destroy self.ownedNFTs
        }

        // initializer
        //
        init () {
            self.ownedNFTs <- {}
        }
    }

    // createEmptyCollection
    // public function that anyone can call to create a new empty collection
    //
    pub fun createEmptyCollection(): @NonFungibleToken.Collection {
        return <- create Collection()
    }

    // NFTMinter
    // Resource that an admin or something similar would own to be
    // able to mint new NFTs
    //
    pub resource NFTMinter {

        // mintNFT
        // Mints a new NFT with a new ID
        // and deposit it in the recipients collection using their collection reference
        //
        pub fun mintNFT(
            recipient: &{NonFungibleToken.CollectionPublic}, 
            description: String,
            image: String,
            name: String,
            series: String

        ) {
            // deposit it in the recipient's account using their reference
            recipient.deposit(token: <-create NFTExample.NFT(
                id: NFTExample.totalSupply,
                description: description,
                image: image,
                name: name,
                series: series
            ))

            emit Minted(
                id: NFTExample.totalSupply,
                name: name
            )

            NFTExample.totalSupply = NFTExample.totalSupply + (1 as UInt64)
        }
    }

    // fetch
    // Get a reference to a NFTExample from an account's Collection, if available.
    // If an account does not have a NFTExample.Collection, panic.
    // If it has a collection but does not contain the itemID, return nil.
    // If it has a collection and that collection contains the itemID, return a reference to that.
    //
    pub fun fetch(_ from: Address, itemID: UInt64): &NFTExample.NFT? {
        let collection = getAccount(from)
            .getCapability(NFTExample.CollectionPublicPath)!
            .borrow<&NFTExample.Collection{NFTExample.NFTExampleCollectionPublic}>()
            ?? panic("Couldn't get collection")
        // We trust NFTExample.Collection.borowNFTExample to get the correct itemID
        // (it checks it before returning it).
        return collection.borrowNFTExample(id: itemID)
    }

    // initializer
    //
    init() {
        // set rarity price mapping

        // Set our named paths
        self.CollectionStoragePath = /storage/NFTExampleCollectionV10
        self.CollectionPublicPath = /public/NFTExampleCollectionV10
        self.MinterStoragePath = /storage/NFTExampleMinterV10

        // Initialize the total supply
        self.totalSupply = 0

        // Create a Minter resource and save it to storage
        let minter <- create NFTMinter()
        self.account.save(<-minter, to: self.MinterStoragePath)

        emit ContractInitialized()
    }
}