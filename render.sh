#!/bin/sh

# Make sure the arguments look valid
if [ -z $1 ] || [ -z $2 ] || ([ $2 != "testnet" ] && [ $2 != "mainnet" ])
then
    echo "Usage: bash render.sh [TEMPLATE_NAME] [NETWORK]"
    exit 1
fi

# Compute paths to the .env file and the template file
env_file="$1/$2.env"
template_file="$1/$1.cdc.tmpl"
output_file="$1/$1-$2.cdc"

# Populate environment with values from the .env file
export $(cat $env_file | xargs)

# Render the template
envsubst < $template_file > $output_file

# Output the rendered script hash
sha256sum $output_file
