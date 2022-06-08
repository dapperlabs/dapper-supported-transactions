# Open Pack

This transcation opens an on-chain pack, revealing its contents and placing them into the account's NFT collection.

## Transaction Arguments

`revealID: UInt64` is the ID of the pack NFT to reveal.

## Transaction Authorizers

`owner` is the Dapper user's account. This is the account that owns the pack that is to be opened. Dapper will provide this signature.
