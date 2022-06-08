# Metadata Script

Every purchase transaction for the Dapper Wallet requires a metadata script. This script is used to display the NFT being purchased to the buyer during the checkout flow. Arguments passed to this metadata script should be a subset of the arguments passed to the associated purchase transaction.

## Script Arguments

Arguments passed to this metadata script should be a subset of the arguments passed to the associated purchase transaction. We strongly recommend that the argument ordering should be identical to that of the transaction.

Typical transaction like one shared here uses metadata view implementation to extract the metadata info and return that to the script caller.
