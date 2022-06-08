import MetadataViews from 0x631e88ae7f1d7c20
import NFTStorefront from 0x94b06cfca1d8a476
import Flunks from 0xe666c53e1758dec6 

pub struct PurchaseData {
    pub let id: UInt64
    pub let name: String?
    pub let amount: UFix64
    pub let description: String?
    pub let imageURL: String?

    init(id: UInt64, name: String?, amount: UFix64, description: String?, imageURL: String?) {
        self.id = id
        self.name = name
        self.amount = amount
        self.description = description
        self.imageURL = imageURL
    }
}

pub fun main(address: Address, listingResourceID: UInt64): PurchaseData {


    let account = getAccount(address)
    let marketCollectionRef = account
        .getCapability<&NFTStorefront.Storefront{NFTStorefront.StorefrontPublic}>(
            NFTStorefront.StorefrontPublicPath
        )
        .borrow()
        ?? panic("Could not borrow market collection from address")

    let saleItem = marketCollectionRef.borrowListing(listingResourceID: listingResourceID)
        ?? panic("No item with that ID")

    let listingDetails = saleItem.getDetails()!

    let collection = account.getCapability(Flunks.CollectionPublicPath)
    .borrow<&{Flunks.FlunksCollectionPublic}>()
    ?? panic("Could not borrow a reference to the collection")

    let nft = collection.borrowFlunks(id: listingDetails.nftID) 
            ?? panic("Could not borrow a reference to the collection")

    if let view = nft.resolveView(Type<MetadataViews.Display>()) {
        
        let display = view as! MetadataViews.Display

        let purchaseData = PurchaseData(
            id: listingDetails.nftID,
            name: display.name,
            amount: listingDetails.salePrice,
            description: display.description,
            imageURL: display.thumbnail.uri(),
        )
        
        return purchaseData
    }
     panic("No NFT")
}
