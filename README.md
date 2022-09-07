# Dapper Supported Transactions

This repository contains Flow transaction scripts that the Dapper wallet will support by default. Following these transaction templates will allow for safer and easier integration between dapps and the Dapper Flow wallet. Of course, more transactions will be evaluated and safelisted within the Dapper system as new use cases arise.

## Checklist 
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
