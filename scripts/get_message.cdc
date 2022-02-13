import ColdStorageA from "../contracts/ColdStorageA.cdc"

pub fun main(address: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64): [UInt8] {
  let publicVault = getAccount(address)
    .getCapability(/public/flowTokenColdStorage)!
    .borrow<&ColdStorageA.Vault{ColdStorageA.PublicVault}>()!

  return publicVault.showSignableMessage(address: address, recipientAddress: recipientAddress, amount: amount, seqNo: seqNo)
}

//179b6b1cb6755e31f8d6e0586b0a20c70000000017d784000000000000000000
//179b6b1cb6755e31f8d6e0586b0a20c70000000017d784000000000000000000