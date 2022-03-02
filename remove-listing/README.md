# Purchase NFT (Marketplace)

This transaction removes a listing from the account's storefront.

## Transaction Arguments

`listingResourceID: UInt64` is the ID of the listing that is to be removed.

## Transaction Authorizers

`seller` is the Dapper user's account. This is the account of the seller who no longer wants their NFT to be listed
for sale. Dapper will provide this signature.
