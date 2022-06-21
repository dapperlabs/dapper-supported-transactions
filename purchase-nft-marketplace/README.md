# Purchase NFT (Marketplace)

This transcation purchases an NFT on a peer-to-peer marketplace (i.e. **not** directly from a dapp). This transaction
will also initialize the buyer's NFT collection on their account if it has not already been initialized.

## Transaction Arguments
`merchantAccountAddress: Address` is the official merchant account of the dapp. Dapper team will share this account with the dapp project team.

`listingResourceID: UInt64` is the ID of the listing that holds the NFT that is to be purchased.

`storefrontAddress: Address` is the address of the account that is selling the NFT.

`expectedPrice: UFix64` is the price of the sale. This is used by Dapper in the purchase flow. Because the listing will be
purchased using DapperUtilityCoin, this price will be in USD.

## Transaction Authorizers

`dapper` is Dapper's payer account that provides the DapperUtilityCoin (DUC) for the purchase. Dapper user accounts cannot hold DUC.

`buyer` is the Dapper user's account. This is the account that is buying the NFT. Dapper will provide this signature.
