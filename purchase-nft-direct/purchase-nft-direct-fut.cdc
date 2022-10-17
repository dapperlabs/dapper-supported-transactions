import FungibleToken from ${FungibleTokenContractAddress}
import NonFungibleToken from ${NonFungibleTokenContractAddress}
import NFTStorefront from ${NFTStorefrontContractAddress}
import FlowUtilityToken from ${FlowUtilityTokenContractAddress}
import ${NFTContractName} from ${NFTContractAddress}

// This transaction purchases an NFT from a dapp directly (i.e. **not** on a peer-to-peer marketplace).
// FIRST ARGUMENT OF THIS TRANSACTION MUST BE YOUR MERCHANT ACCOUNT ADDRESS PROVIDED BY DAPPER LABS
transaction(merchantAccountAddress: Address, storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64) {
    let paymentVault: @FungibleToken.Vault
    let buyerNFTCollection: &AnyResource{NonFungibleToken.CollectionPublic}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}
    let balanceBeforeTransfer: UFix64
    let mainFUTVault: &FlowUtilityToken.Vault
    let dappAddress: Address
    let salePrice: UFix64
    
    // "dapp" as authorizer is OPTIONAL
    // If "dapp" is also an authorizer and it MUST be the first authorizer
    prepare(dapp: AuthAccount, dapper: AuthAccount, buyer: AuthAccount) {
        self.dappAddress = dapp.address

        // Initialize the collection if the buyer does not already have one
        if buyer.borrow<&${NFTContractName}.Collection>(from: ${NFTContractName}.CollectionStoragePath) == nil {
            buyer.save(<-${NFTContractName}.createEmptyCollection(), to: ${NFTContractName}.CollectionStoragePath
            buyer.link<&{${NFTContractName}.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
                ${NFTContractName}.CollectionPublicPath,
                target: ${NFTContractName}.CollectionStoragePath
            )
             ?? panic("Could not link collection Pub Path");
        }

        self.storefront = dapp
            .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(NFTStorefront.StorefrontPublicPath)
            .borrow()
            ?? panic("Could not borrow a reference to the storefront")
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Listing with that ID in Storefront")

        self.salePrice = self.listing.getDetails().salePrice

        self.mainFUTVault = dapper.borrow<&FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
                    ?? panic("Could not borrow reference to Flow Utility Token vault")
        self.balanceBeforeTransfer = self.mainFUTVault.balance
        self.paymentVault <- self.mainFUTVault.withdraw(amount: self.salePrice)

        self.buyerNFTCollection = buyer
            .getCapability<&{NonFungibleToken.CollectionPublic}>(PackNFT.CollectionPublicPath)
            .borrow()
            ?? panic("Cannot borrow NFT collection receiver from account")
    }

    pre {
        self.salePrice == expectedPrice: "unexpected price"
        self.dappAddress == ${NFTContractAddress} && self.dappAddress == storefrontAddress: "Requires valid authorizing signature"
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault
        )

        self.buyerNFTCollection.deposit(token: <-item)
    }

    post {
        self.mainFUTVault.balance == self.balanceBeforeTransfer: "FUT leakage"
    }
}
