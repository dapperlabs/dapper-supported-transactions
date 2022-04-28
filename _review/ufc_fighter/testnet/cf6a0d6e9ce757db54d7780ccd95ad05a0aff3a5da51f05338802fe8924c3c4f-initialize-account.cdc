import UFC_FIGHTER_NFT from 0x30b1e8c26734cc64
import UFC_NFT from 0x30b1e8c26734cc64
import NonFungibleToken from 0x631e88ae7f1d7c20

// This transcation initializes an account with a collection that allows it to hold NFTs from a specific contract. It will
// do nothing if the account is already initialized.
transaction {
    prepare(collector: AuthAccount) {
        if collector.borrow<&UFC_FIGHTER_NFT.Collection>(from: UFC_FIGHTER_NFT.CollectionStoragePath) == nil {
            let collection1 <- UFC_FIGHTER_NFT.createEmptyCollection() as! @UFC_FIGHTER_NFT.Collection
            collector.save(<-collection1, to: UFC_FIGHTER_NFT.CollectionStoragePath)
            collector.link<&UFC_FIGHTER_NFT.Collection{UFC_FIGHTER_NFT.UFC_FIGHTER_NFTCollectionPublic, NonFungibleToken.CollectionPublic}>(
                UFC_FIGHTER_NFT.CollectionPublicPath,
                target: UFC_FIGHTER_NFT.CollectionStoragePath,
            )
        }
        if collector.borrow<&UFC_NFT.Collection>(from: UFC_NFT.CollectionStoragePath) == nil {
            let collection2 <- UFC_NFT.createEmptyCollection()
            signer.save<@NonFungibleToken.Collection>(<-collection2, to: UFC_NFT.CollectionStoragePath)
            signer.link<&{NonFungibleToken.CollectionPublic}>(UFC_NFT.CollectionPublicPath, target: UFC_NFT.CollectionStoragePath)
        }
    }
}
