# Dapper Supported Transactions

This repository contains Flow transaction scripts that the Dapper wallet will support by default. Following these transaction templates will allow for safer and easier integration between dapps and the Dapper Flow wallet. Of course, more transactions will be evaluated and safelisted within the Dapper system as new use cases arise.

## Checklist for developers submitting transactions for review
1. Purchase transactions:

    a) Make sure the first argument is either the merchant account address or storefront address

    b) The metadata script has the same set of arguments as the purchase transaction

    c) The metadata script returns PurchaseData structure


2. Setup transactions and Purchase transactions should expose MetadataView.Resolver interface.
3. Purchase transactions or Create Listing transactions should ideally not sell or buy multiple items.
4. All transactions should have a DUC leakage check
5. Any transfer of NFT to an arbitrary Flow address is not allowed
6. Transfer to a hardcoded address is ok, but Dapper compliance should sign off on it
7. Royalty percentage is allowed as a parameter only if the dapp is signing the transaction
8. Transactions should not be creating any fungible token receivers or dealing with any fungible tokens other than $DUC or $FUT.
9. All purchase transactions should have DUC/FUT leak check.
10. For $FLOW/$FUT purchases there is a new field in the PurchaseData structure returned by the metadata scripts submitted along with purchase txn. Ensure that the new 


## Supporting $FLOW payments
Supporting $FLOW purchase on a Dapper Dapp requires the following changes:
1. Smart Contracts: No changes are needed. Please make sure your NFT contracts follow Flow nft standard, implement metadata standard, and are added to the Flow NFT Catalog.
2. Transactions: Similar to how you built transactions with Dapper Utility Coin ($DUC) to enable fiat payments for the Dapper Wallet, you need to build transactions with Flow Utility Token ($FUT) for $FLOW payments. 
3. Base your transactions on the templates included in this repo.
4. Create NFT sale listing in $FUT. See this. In case of P2P listing, your code should check if the seller Flow account has a $FUT receiver setup. If not, you should warn the user that they can not receive $FLOW by listing items for sale.
5. Craft your purchase transactions to use $FUT. See the template transactions in this repo.
6. Metadata Scripts for Purchase transactions: We are adding a new field in the metadata PurchaseData struct called `pub let paymentVaultTypeID: Type`. You can fill the new field by calling getType() function of the payment vault type. It is possible to construct a transaction/metadata script that works for $DUC and $FUT as long as this new metadata field is used. See the example in this repo.
7. Frontend/FCL code: Obviously, your frontend should show listings in $FLOW rather than $USD. 

Note the $FUT deployment addresses are in mainnet.env and testnet.env files in this repo.


## Rendering Transaction Templates

```shell
$ bash render.sh [TEMPLATE_NAME] [NETWORK]
```

Check out the templates and find the one that fits your use case best. Let's say it's `create-listing`, and you'd like to render a transaction template for use on `testnet`.

1. Open `create-listing/testnet.env` and fill in the missing template variables.
2. Run the folowing command to render the template using the variables you set in `testnet.env`
```shell
$ bash render.sh create-listing testnet
```
This command will output the result to `create-listing/create-listing-testnet.cdc` and will print the SHA2 256 script hash.
