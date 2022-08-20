# Purchase NFT (Marketplace)

This transcation purchases a pack on from a dapp. This tranasction will also initialize the buyer's account with a pack NFT
collection and an NFT collection if it does not already have them.

This tranaction should be used in conjunction with a pack NFT reservation system that can reserve a pack NFT specifically
for the buyer before this transaction is signed as a means of ensuring it is available for purchase by the specific
buyer in this transaction. Direct purchase of pack NFTs from dapps without reservation is not recommended as it introduces
a variety of security and usability concerns.

## Transaction Arguments
`merchantAccountAddress: Address` is the official merchant account of the dapp. Dapper team will share this account with the dapp project team.

`listingResourceID: UInt64` is the ID of the listing that holds the pack NFT that is to be purchased.

`storefrontAddress: Address` is the address of the account that is selling the pack NFT.

`saleItemPrice: UFix64` is the price that the NFT will be listed for.

If the listing is purchased using DapperUtilityCoin, this price will be in USD. i.e. if `saleItemPrice` is `1.50`, the item costs USD $1.50

If the listing is purchased using FlowUtilityToken, this price will be in Flow. i.e. if `saleItemPrice` is `1.50`, the item costs 1.50 Flow

## Transaction Authorizers

`dapp` is the dapp's account. This should generally be the account to which the NFT contract was deployed. This account
holds the pack listings that are being purchased. It's important that the dapp signs this transaction as a means of verifying that
the buyer is allowed to buy the pack. Packs should be reserved before purchase to ensure that the buyer gets the pack after
having paid.

`dapper` is Dapper's payer account that provides the DapperUtilityCoin/FlowUtilityToken (DUC/FUT) for the purchase. Dapper user accounts cannot hold DUC/FUT.

`buyer` is the Dapper user's account. This is the account that is buying the NFT. Dapper will provide this signature.
