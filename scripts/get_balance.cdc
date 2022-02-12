import ColdStorageA from "../contracts/ColdStorageA.cdc"

pub fun main(address: Address): UFix64 {
  let publicVault = getAccount(address)
    .getCapability(/public/flowTokenColdStorage)!
    .borrow<&ColdStorageA.Vault{ColdStorageA.PublicVault}>()!

  return publicVault.getBalance()
}