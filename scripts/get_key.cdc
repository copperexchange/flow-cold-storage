import ColdStorageA from 0x3acec2357e49866e

pub fun main(address: Address): [ColdStorageA.Key] {
  let publicVault = getAccount(address)
    .getCapability(/public/flowTokenColdStorage)!
    .borrow<&ColdStorageA.Vault{ColdStorageA.PublicVault}>()!

  return publicVault.getKeys()
}