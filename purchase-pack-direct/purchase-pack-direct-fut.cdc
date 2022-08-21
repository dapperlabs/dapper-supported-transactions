import FungibleToken from ${FungibleTokenContractAddress}
import NonFungibleToken from ${NonFungibleTokenContractAddress}
import NFTStorefront from ${NFTStorefrontContractAddress}
import PackNFT from ${PackNFTAddress}
import FlowUtilityToken from ${FlowUtilityTokenContractAddress}
import ${NFTContractName} from ${NFTContractAddress}

// This transaction purchases a pack from a dapp. This transaction will also initialize the buyer's account with a pack NFT
// collection and an NFT collection if it does not already have them.
transaction(merchantAccountAddress: Address, storefrontAddress: Address, listingResourceID: UInt64, expectedPrice: UFix64) {
    let paymentVault: @FungibleToken.Vault
    let buyerNFTCollection: &AnyResource{NonFungibleToken.CollectionPublic}
    let storefront: &NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}
    let listing: &NFTStorefront.Listing{NFTStorefront.ListingPublic}
    let balanceBeforeTransfer: UFix64
    let mainFUTVault: &FlowUtilityToken.Vault
    let dappAddress: Address
    let salePrice: UFix64

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

        // Initialize the PackNFT collection if the buyer does not already have one
        if buyer.borrow<&PackNFT.Collection>(from: PackNFT.CollectionStoragePath) == nil {
            buyer.save(<-PackNFT.createEmptyCollection(), to: PackNFT.CollectionStoragePath);
            buyer.link<&{NonFungibleToken.CollectionPublic}>(PackNFT.CollectionPublicPath, target: PackNFT.CollectionStoragePath)
                ?? panic("Could not link PackNFT.Collection Pub Path");
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
