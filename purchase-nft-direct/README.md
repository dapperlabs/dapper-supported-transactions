# Purchase NFT (Direct)

This transcation purchases an NFT from a dapp directly (i.e. **not** on a peer-to-peer marketplace).

This tranaction should be used in conjunction with an NFT reservation system that can reserve an NFT specifically
for the buyer before this transaction is signed as a means of ensuring it is available for purchase by the specific
buyer in this transaction. Direct purchase of NFTs from dapps without reservation is not recommended as it introduces
a variety of security and usability concerns.

## Transaction Arguments

`listingResourceID: UInt64` is the ID of the listing that holds the NFT that is to be purchased.

`storefrontAddress: Address` is the address of the account that is selling the NFT. This should be the same as the NFT contract
address.

`expectedPrice: UFix64` is the price of the sale. This is used by Dapper in the purchase flow.

## Transaction Authorizers

`dapp` is the dapp's account. This is the account that holds the NFT being purchased. It's important that the dapp signs this
transaction as a means of verifying that the NFT being purchased is reserved specifically for the buyer.

`dapper` is Dapper's payer account that provides the DapperUtilityCoin (DUC) for the purchase. Dapper user accounts cannot hold DUC.

`buyer` is the Dapper user's account. This is the account that owns the pack that is to be opened. Dapper will provide this signature.
