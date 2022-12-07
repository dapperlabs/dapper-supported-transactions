import FungibleToken from ${FungibleTokenContractAddress}
import NonFungibleToken from ${NonFungibleTokenContractAddress}
import FlowUtilityToken from ${FlowUtilityTokenContractAddress}
import NFTStorefrontV2 from ${NFTStorefrontV2ContractAddress}
import ${NFTContractName} from ${NFTContractAddress}
import MetadataViews from ${MetadataViewsContractAddress}
import FlowUtilityToken from ${FlowUtilityTokenContractAddress}


/// Transaction facilitates the purchase of listed NFT.
/// It takes the storefront address, listing resource that need
/// to be purchased & a address that will takeaway the commission.
///
/// Buyer of the listing (,i.e. underling NFT) would authorize and sign the
/// transaction and if purchase happens then transacted NFT would store in
/// buyer's collection.
transaction(storefrontAddress: Address, listingResourceID: UInt64, commissionRecipient: Address) {
    let paymentVault: @FungibleToken.Vault
    let nftCollection: &${NFTContractName}.Collection{NonFungibleToken.Receiver}
    let storefront: &NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}
    let listing: &NFTStorefrontV2.Listing{NFTStorefrontV2.ListingPublic}
    let commissionRecipientCap: Capability<&{FungibleToken.Receiver}>
    let balanceBeforeTransfer: UFix64
    let mainFlowUtilityTokenVault: &FlowUtilityToken.Vault

    prepare(dapper: AuthAccount, buyer: AuthAccount) {
        // Initialize the buyer's collection if they do not already have one
        if buyer.borrow<&${NFTContractName}.Collection>(from: ${NFTContractName}.CollectionStoragePath) == nil {
            let collection <- ${NFTContractName}.createEmptyCollection() as! @${NFTContractName}.Collection
            buyer.save(<-collection, to: ${NFTContractName}.CollectionStoragePath)
            
            buyer.link<&${NFTContractName}.Collection{NonFungibleToken.CollectionPublic, MetadataViews.ResolverCollection}>(
                ${NFTContractName}.CollectionPublicPath,
                target: ${NFTContractName}.CollectionStoragePath
            )
             ?? panic("Could not link collection Pub Path");
        }

        // Get the storefront reference from the seller
        self.storefront = getAccount(storefrontAddress)
            .getCapability<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(
                NFTStorefrontV2.StorefrontPublicPath
            )!
            .borrow()
            ?? panic("Could not borrow Storefront from provided address")

        // Get the listing by ID from the storefront
        self.listing = self.storefront.borrowListing(listingResourceID: listingResourceID)
            ?? panic("No Offer with that ID in Storefront")
        let salePrice = self.listing.getDetails().salePrice

        // Get a FUT vault from Dapper's account
        self.mainFlowUtilityTokenVault = dapper.borrow<&FlowUtilityToken.Vault>(from: /storage/flowUtilityTokenVault)
            ?? panic("Cannot borrow FlowUtilityToken vault from account storage")
        self.balanceBeforeTransfer = self.mainFlowUtilityTokenVault.balance
        self.paymentVault <- self.mainFlowUtilityTokenVault.withdraw(amount: salePrice)

        // Get the collection from the buyer so the NFT can be deposited into it
        self.nftCollection = buyer.borrow<&${NFTContractName}.Collection{NonFungibleToken.Receiver}>(
            from: ${NFTContractName}.CollectionStoragePath
        ) ?? panic("Cannot borrow NFT collection receiver from account")

        // Get a reference to the commission recipient that will receive the commission fees if the sale executes.
        // Note that the commission recipient should be an account owned by Dapper or an end-user Dapper Wallet account address.
        self.commissionRecipientCap = getAccount(commissionRecipient).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.commissionRecipientCap.check(), message: "Commission Recipient doesn't have FlowUtilityToken receiving capability")
    }

    execute {
        let item <- self.listing.purchase(
            payment: <-self.paymentVault,
            commissionRecipient: self.commissionRecipientCap
        )

        self.nftCollection.deposit(token: <-item)
    }

    // Check that all flowUtilityToken was routed back to Dapper
    post {
        self.mainFlowUtilityTokenVault.balance == self.balanceBeforeTransfer: "FlowUtilityToken leakage"
    }
}
