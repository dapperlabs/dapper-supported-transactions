import FungibleToken from 0x9a0766d93b6608b7
import TokenForwarding from 0x51ea0e37c27a1f1a
import FlowUtilityToken from 0x82ec283f88a62e65

/** 
  To receive the payment on-chain in FUT, the Storefront account must create a special resource called a Forwarder. 
  The Forwarder ensures that the Storefront is properly credited for purchases made by Dapper users. 
**/

transaction(dapperAccountAddress: Address) {

	prepare(acct: AuthAccount) {
		// Get a Receiver reference for the Dapper account that will be the recipient of the forwarded FUT
		let dapper = getAccount(dapperAccountAddress)
	  	let dapperFUTReceiver = dapper.getCapability(/public/flowUtilityTokenReceiver)!

		// Create a new Forwarder resource for FUT and store it in the new account''s storage
		let futForwarder <- TokenForwarding.createNewForwarder(recipient: dapperFUTReceiver)
		acct.save(<-futForwarder, to: /storage/flowUtilityTokenReceiver)

		// Publish a Receiver capability for the new account, which is linked to the FUT Forwarder
		acct.link<&{FungibleToken.Receiver}>(/public/flowUtilityTokenReceiver, target: /storage/flowUtilityTokenReceiver)
	}
}
