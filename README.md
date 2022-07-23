# Dapper Supported Transactions

This repository contains Flow transaction scripts that the Dapper wallet will support by default. Following these transaction templates will allow for safer and easier integration between dapps and the Dapper Flow wallet. Of course, more transactions will be evaluated and safelisted within the Dapper system as new use cases arise.

## Rendering Transaction Templates

```shell
$ bash render.sh [TEMPLATE_NAME] [NETWORK]
```
or
```shell
$ bash all.sh [NETWORK] // loops directories
```

## Rendering Transaction Environment

Overlay environment with each folder `<tx-name>/<network>.env` and shared `./<network>.env` both optional

Example 
1. Open `create-listing/testnet.env` or `./testnet.env` and fill in the missing template variables.
2. Run the folowing command to render `testnet.env`
```shell
$ bash render.sh create-listing testnet
```
This command will output the result to `create-listing/create-listing-testnet.cdc` and will print the SHA2 256 script hash.
