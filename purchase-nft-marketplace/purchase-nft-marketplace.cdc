import FungibleToken from ${FungibleTokenContractAddress}
import NonFungibleToken from ${NonFungibleTokenContractAddress}
import DapperUtilityCoin from ${DapperUtilityCoinContractAddress}
import NFTStorefront from ${NFTStorefrontContractAddress}
import ${NFTContractName} from ${NFTContractAddress}

// This transaction purchases an NFT on a peer-to-peer marketplace (i.e. **not** directly from a dapp). This transaction
// will also initialize the buyer's NFT collection on their account if it has not already been initialized.
// FIRST ARGUMENT OF A P2P PURCHASE TRANSACTION SHOULD ALWAYS BE THE SELLER'S ADDRESS
transaction(storefrontAddress: Address, listingResourceID: UInt64,  expectedPrice: UFix64) {
    let paymentVault: @FungibleToken.Vault
    let nftCollection: &${NFTContractName}.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}
    let salePrice: UFix64
    let balanceBeforeTransfer: UFix64
    let mainDapperUtilityCoinVault: &DapperUtilityCoin.Vault

    prepare(dapper: AuthAccount, buyer: AuthAccount) {
        // Initialize the buyer's collection if they do not already have one
        if buyer.borrow<&${NFTContractName}.Collection>(from: ${NFTContractName}.CollectionStoragePath) == nil {
            let collection <- ${NFTContractName}.createEmptyCollection() as! @${NFTContractName}.Collection
            buyer.save(<-collection, to: ${NFTContractName}.CollectionStoragePath)
            
            buyer.link<&{${NFTContractName}.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
                ${NFTContractName}.CollectionPublicPath,
                target: ${NFTContractName}.CollectionStoragePath
            )
             ?? panic("Could not link collection Pub Path");
        }

        // Get the storefront reference from the seller
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        // Get the listing by ID from the storefront
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Offer with that ID in Storefront")
        self.salePrice = self.listing.getDetails().salePrice

        // Get a DUC vault from Dapper's account
        self.mainDapperUtilityCoinVault = dapper.borrow<&DapperUtilityCoin.Vault>(from: /storage/dapperUtilityCoinVault)
            ?? panic("Cannot borrow DapperUtilityCoin vault from account storage")
        self.balanceBeforeTransfer = self.mainDapperUtilityCoinVault.balance
        self.paymentVault <- self.mainDapperUtilityCoinVault.withdraw(amount: self.salePrice)

        // Get the collection from the buyer so the NFT can be deposited into it
        self.nftCollection = buyer.borrow<&${NFTContractName}.Collection{NonFungibleToken.Receiver}>(
            from: ${NFTContractName}.CollectionStoragePath
        ) ?? panic("Cannot borrow NFT collection receiver from account")
    }

    // Check that the price is right
    pre {
        self.salePrice == expectedPrice: "unexpected price"
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.nftCollection.deposit(token: <-item)

        // Remove listing-related information from the storefront since the listing has been purchased.
        self.storefront.cleanup(listingResourceID: listingResourceID)
    }

    // Check that all dapperUtilityCoin was routed back to Dapper
    post {
        self.mainDapperUtilityCoinVault.balance == self.balanceBeforeTransfer: "DapperUtilityCoin leakage"
    }
}
