import FungibleToken from ${FungibleTokenContractAddress}
import NonFungibleToken from ${NonFungibleTokenContractAddress}
import FlowUtilityToken from ${FlowUtilityTokenContractAddress}
import NFTStorefront from ${NFTStorefrontContractAddress}
import TokenForwarding from ${TokenForwardingContractAddress}
import ${NFTContractName} from ${NFTContractAddress}

// This transcation can be used to place and NFT for sale on a marketplace such that a specified percentage of the proceeds of the sale
// go to the dapp as a royalty.
transaction(saleItemID: UInt64, saleItemPrice: UFix64, royaltyPercent: UFix64) {
    let sellerPaymentReceiver: Capability<&{FungibleToken.Receiver}>
    let nftProvider: Capability<&${NFTContractName}.Collection{NonFungibleToken.Provider, NonFungibleToken.CollectionPublic}>
    let storefront: &NFTStorefront.Storefront
    let dappAddress: Address

    // It's important that the dapp account authorize this transaction so the dapp has the ability
    // to validate and approve the royalty included in the sale.
    prepare(dapp: AuthAccount, seller: AuthAccount) {
        self.dappAddress = dapp.address

        // If the account doesn't already have a storefront, create one and add it to the account
        if seller.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath) == nil {
            let newstorefront <- NFTStorefront.createStorefront() as! @NFTStorefront.Storefront
            seller.save(<-newstorefront, to: NFTStorefront.StorefrontStoragePath)
            seller.link<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
                NFTStorefront.StorefrontPublicPath,
                target: NFTStorefront.StorefrontStoragePath
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

        // Get a reference to the user's NFT storefront
        self.storefront = seller.borrow<&NFTStorefront.Storefront>(from: NFTStorefront.StorefrontStoragePath)
            ?? panic("Missing or mis-typed NFTStorefront Storefront")
    }

    // Make sure dapp is actually the dapp and not some random account
    pre {
        self.dappAddress == ${NFTContractAddress}: "Requires valid authorizing signature"
    }

    execute {
        // Calculate the amout the seller should receive if the sale executes, and the amount
        // that should be sent to the dapp as a royalty.
        let amountSeller = saleItemPrice * (1.0 - royaltyPercent)
        let amountRoyalty = saleItemPrice - amountSeller

        // Get the royalty recipient's public account object
        // Note that the royalty receiver should be an account owned by Dapper (aka MerchantAddress) or an end-user Dapper Wallet account address.
        let royaltyRecipient = getAccount(${RoyaltyReceiverAddress})

        // Get a reference to the royalty recipient's Receiver
        let royaltyReceiverRef = royaltyRecipient.getCapability<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver)
        assert(royaltyReceiverRef.borrow() != nil, message: "Missing or mis-typed FlowUtilityToken royalty receiver")

        let saleCutSeller = NFTStorefront.SaleCut(
            receiver: self.sellerPaymentReceiver,
            amount: amountSeller
        )

        let saleCutRoyalty = NFTStorefront.SaleCut(
            receiver: royaltyReceiverRef,
            amount: amountRoyalty
        )

        self.storefront.createListing(
            nftProviderCapability: self.nftProvider,
            nftType: Type<@${NFTContractName}.NFT>(),
            nftID: saleItemID,
            salePaymentVaultType: Type<@FlowUtilityToken.Vault>(),
            saleCuts: [saleCutSeller, saleCutRoyalty]
        )
    }
}
