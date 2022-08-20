# Purchase NFT (Marketplace)

This transcation purchases an NFT on a peer-to-peer marketplace (i.e. **not** directly from a dapp). This transaction
will also initialize the buyer's NFT collection on their account if it has not already been initialized.

## Transaction Arguments
`storefrontAddress: Address` is the address of the account that is selling the NFT. This should always be the first argument in a P2P transaction.

`listingResourceID: UInt64` is the ID of the listing that holds the NFT that is to be purchased.

`saleItemPrice: UFix64` is the price that the NFT will be listed for.

If the listing is purchased using DapperUtilityCoin, this price will be in USD. i.e. if `saleItemPrice` is `1.50`, the item costs USD $1.50

If the listing is purchased using FlowUtilityToken, this price will be in Flow. i.e. if `saleItemPrice` is `1.50`, the item costs 1.50 Flow

## Transaction Authorizers

`dapper` is Dapper's payer account that provides the DapperUtilityCoin/FlowUtilityToken (DUC/FUT) for the purchase. Dapper user accounts cannot hold DUC/FUT.

`buyer` is the Dapper user's account. This is the account that is buying the NFT. Dapper will provide this signature.
