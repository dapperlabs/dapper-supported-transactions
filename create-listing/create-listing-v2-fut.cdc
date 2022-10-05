import FungibleToken from ${FungibleTokenContractAddress}
import NonFungibleToken from ${NonFungibleTokenContractAddress}
import FlowUtilityToken from ${FlowUtilityTokenContractAddress}
import NFTStorefrontV2 from ${NFTStorefrontV2ContractAddress}
import MetadataViews from ${MetadataViewsContractAddress}
import TokenForwarding from ${TokenForwardingContractAddress}
import ${NFTContractName} from ${NFTContractAddress}

/// Transaction used to facilitate the creation of the listing under the signer's owned storefront resource.
/// It accepts the certain details from the signer,i.e. - 
///
/// `saleItemID` - ID of the NFT that is put on sale by the seller.
/// `saleItemPrice` - Amount of tokens (FT) buyer needs to pay for the purchase of listed NFT.
/// `customID` - Optional string to represent identifier of the dapp.
/// `commissionAmount` - Commission amount that will be taken away by the purchase facilitator.
/// `expiry` - Unix timestamp at which created listing become expired.
/// `marketplacesAddress` - List of addresses that are allowed to get the commission.
transaction(saleItemID: UInt64, saleItemPrice: UFix64, customID: String?, commissionAmount: UFix64, expiry: UInt64, marketplacesAddress: [Address]) {
    let sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
    let nftProvider: Capability<&${NFTContractName}.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefrontV2.Storefront
    var saleCuts: [NFTStorefrontV2.SaleCut]
    var marketplacesCapability: [Capability<&AnyResource{FungibleToken.Receiver}>]

    prepare(seller: AuthAccount) {
        self.saleCuts = []
        self.marketplacesCapability = []
        
        // If the account doesn't already have a storefront, create one and add it to the account
        if seller.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath) == nil {
            let storefront <- NFTStorefrontV2.createStorefront() as! @NFTStorefrontV2.Storefront
            seller.save(<-storefront, to: NFTStorefrontV2.StorefrontStoragePath)
            seller.link<&NFTStorefrontV2.Storefront{NFTStorefrontV2.StorefrontPublic}>(
                NFTStorefrontV2.StorefrontPublicPath,
                target: NFTStorefrontV2.StorefrontStoragePath
            )
        }

        // FUT Setup if the user's account is not initialized with FUT receiver
        if seller.borrow<&{FungibleToken.Receiver}>(from: /storage/flowUtilityTokenReceiver) == nil {

            let dapper = getAccount(${FlowUtilityTokenContractAddress})
            let dapperFUTReceiver = dapper.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!

            // Create a new Forwarder resource for FUT and store it in the new account's storage
            let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
            seller.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)

            // Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
            seller.link<&FlowUtilityToken.Vault{FungibleToken.Receiver}>(
                /public/flowUtilityTokenReceiver,
                target: /storage/flowUtilityTokenReceiver
            )
        }

        // Get a reference to the receiver that will receive the fungible tokens if the sale executes.
        // Note that the sales receiver aka MerchantAddress should be an account owned by Dapper or an end-user Dapper Wallet account address.
        self.sellerPaymentReceiver = getAccount(${MerchantAddress}).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(self.sellerPaymentReceiver.borrow() != nil, message: "Missing or mis-typed FlowUtilityToken receiver")

        // If the user does not have their collection linked to their account, link it.
        let nftProviderPrivatePath = /private/${NFTContractName}CollectionProviderForNFTStorefront
        let hasLinkedCollection = seller.
            getCapability<&${NFTContractName}.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(
                nftProviderPrivatePath
            )!.check()
        if !hasLinkedCollection {
            seller.link<&${NFTContractName}.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(
                nftProviderPrivatePath,
                target: ${NFTContractName}.CollectionStoragePath
            )
        }

        // Get a capability to access the user's NFT collection.
        self.nftProvider = seller.
            getCapability<&${NFTContractName}.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>(
                nftProviderPrivatePath
            )!
        assert(self.nftProvider.borrow() != nil, message: "Missing or mis-typed collection provider")

        let collection = seller
            .getCapability(${NFTContractName}.CollectionPublicPath)
            .borrow<&{${NFTContractName}.CollectionPublic}>()
            ?? panic("Could not borrow a reference to the collection")
        var totalRoyaltyCut = 0.0
        let effectiveSaleItemPrice = saleItemPrice - commissionAmount
        let nft = collection.borrowExampleNFT(id: saleItemID)!
        // Check whether the NFT implements the MetadataResolver or not.
        if nft.getViews().contains(Type<MetadataViews.Royalties>()) {
            let royaltiesRef = nft.resolveView(Type<MetadataViews.Royalties>())?? panic("Unable to retrieve the royalties")
            let royalties = (royaltiesRef as! MetadataViews.Royalties).getRoyalties()
            for royalty in royalties {
                // Royalty receiver needs to be a valid Dapper wallet
                let receiver = royalty.receiver.borrow()!
                let dapperFUTReceiver = receiver.owner!.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)!
                assert(dapperFUTReceiver.borrow() != nil, message: "Royalty receiver does not have FlowUtilityToken receiving capability")
                self.saleCuts.append(NFTStorefrontV2.SaleCut(receiver: dapperFUTReceiver, amount: royalty.cut * effectiveSaleItemPrice))
                totalRoyaltyCut = totalRoyaltyCut + royalty.cut * effectiveSaleItemPrice
            }
        }
        // Append the cut for the seller.
        self.saleCuts.append(NFTStorefrontV2.SaleCut(
            receiver: self.sellerPaymentReceiver,
            amount: effectiveSaleItemPrice - totalRoyaltyCut
        ))

        // Get a reference to the user's NFT storefront
        self.storefront = acct.borrow<&NFTStorefrontV2.Storefront>(from: NFTStorefrontV2.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")

        for marketplace in marketplacesAddress {
            // Here we are making a fair assumption that all provided addresses 
            // are either the dapp's merchant address (shared by the Dapper team
            // with the dapp project team) or an end-user Dapper Wallet account address
            // that has the capability to receive `FlowUtilityToken`
            self.marketplacesCapability.append(getAccount(marketplace).getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver))
        }
    }

    execute {
        // Create listing
        self.storefront.createListing(
            nftProviderCapability: self.nftProvider,
            nftType: Type<@${NFTContractName}.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowUtilityToken.Vault>(),
            saleCuts: self.saleCuts,
            marketplacesCapability: self.marketplacesCapability.length == 0 ? nil : self.marketplacesCapability,
            customID: customID,
            commissionAmount: commissionAmount,
            expiry: expiry
        )
    }
}
