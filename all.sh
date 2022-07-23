#!/bin/sh

# Make sure the arguments look valid
if [ -z $1 ] || ([ $1 != "testnet" ] && [ $1 != "mainnet" ])
then
    echo "Usage: bash all.sh [NETWORK]"
    exit 1
fi
for dir in */; do
    DIRNAME=${dir%/}
    /bin/bash render.sh $DIRNAME $1
done