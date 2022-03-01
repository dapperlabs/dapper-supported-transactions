# Purchase NFT (Marketplace)

This transcation purchases a pack on from a dapp. This tranasction will also initialize the buyer's account with a pack NFT
collection and an NFT collection if it does not already have them.

This tranaction should be used in conjunction with a pack NFT reservation system that can reserve a pack NFT specifically
for the buyer before this transaction is signed as a means of ensuring it is available for purchase by the specific
buyer in this transaction. Direct purchase of pack NFTs from dapps without reservation is not recommended as it introduces
a variety of security and usability concerns.

## Transaction Arguments

`listingResourceID: UInt64` is the ID of the listing that holds the pack NFT that is to be purchased.

`storefrontAddress: Address` is the address of the account that is selling the pack NFT.

`expectedPrice: UFix64` is the price of the sale. This is used by Dapper in the purchase flow. Because the listing will be
purchased using DapperUtilityCoin, this price will be in USD.

## Transaction Authorizers

`dapp` is the dapp's account. This should generally be the account to which the NFT contract was deployed. This account
holds the pack listings that are being purchased. It's important that the dapp signs this transaction as a means of verifying that
the buyer is allowed to buy the pack. Packs should be reserved before purchase to ensure that the buyer gets the pack after
having paid.

`dapper` is Dapper's payer account that provides the DapperUtilityCoin (DUC) for the purchase. Dapper user accounts cannot hold DUC.

`buyer` is the Dapper user's account. This is the account that is buying the NFT. Dapper will provide this signature.
