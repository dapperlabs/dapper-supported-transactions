import NFTStorefront from ${NFTStorefrontContractAddress}
import DapperUtilityCoin from ${DapperUtilityCoinContractAddress}
import FungibleToken from ${FungibleTokenContractAddress}
import ${NFTContractName} from ${NFTContractAddress}

// This transcation initializes an account with a collection that allows it to hold NFTs from a specific contract. It will
// do nothing if the account is already initialized.
transaction {
    prepare(collector: AuthAccount) {
        if collector.borrow<&${NFTContractName}.Collection>(from: ${NFTContractName}.CollectionStoragePath) == nil {
            let collection <- ${NFTContractName}.createEmptyCollection() as! @${NFTContractName}.Collection
            collector.save(<-collection, to: ${NFTContractName}.CollectionStoragePath)
            collector.link<&{${NFTContractName}.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
                ${NFTContractName}.CollectionPublicPath,
                target: ${NFTContractName}.CollectionStoragePath,
            )
        }
    }
}
