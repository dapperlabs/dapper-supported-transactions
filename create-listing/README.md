# Create Listing

This transaction can be used to place and NFT for sale on a marketplace such that a specified percentage of the proceeds of the sale
go to the dapp as a royalty.

Important note: Sales proceeds recipient and royalty recipients need to be either the dapp's merchant address (shared by the Dapper team
with the dapp project team) or an end-user Dapper Wallet account address.

## Transaction Arguments

`saleItemID: UInt64` specifies the ID of the NFT that will be put up for sale.

`saleItemPrice: UFix64` is the price that the NFT will be listed for.

If the listing is purchased using DapperUtilityCoin, this price will be in USD. i.e. if `saleItemPrice` is `1.50`, the item costs USD $1.50

If the listing is purchased using FlowUtilityToken, this price will be in Flow. i.e. if `saleItemPrice` is `1.50`, the item costs 1.50 Flow

`royaltyPercent: UFix64` is the precent of the sale price that will be taken by the dapp as a royalty if someone purchases this NFT represented
as a value between 0 and 1. It's important that the dapp validates this argument before signing the transaction.

## Transaction Authorizers

`dapp` is the dapp's signing account. This account should be the same as the account on which the NFT contract is deployed. In other words,
its address should match the `${NFTContractAddress}` for this transaction. This authorizer should only sign the transaction if the `royaltyPercent`
argument has the right value.

`seller` is the Dapper user's account. This is the account from which the listing will be created, and it will receive `1 - royaltyPercent` of
the proceeds of the sale should it execute. Dapper will provide this signature.
