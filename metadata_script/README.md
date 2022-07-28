# Metadata Script

Every purchase transaction for the Dapper Wallet requires a metadata script. This script is used to display the NFT being purchased to the buyer during the checkout flow. 
## Arguments passed to this metadata script should be the same set of arguments passed to the associated purchase transaction.
## Do test this script through flow-cli

## Script Arguments

Typical transaction like one shared here uses metadata view implementation to extract the metadata info and return that to the script caller.
