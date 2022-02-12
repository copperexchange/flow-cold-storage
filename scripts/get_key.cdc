import ColdStorage from 0x8b7e0b1056e8f550

pub fun main(address: Address): ColdStorage.Key {
  let publicVault = getAccount(address)
    .getCapability(/public/flowTokenColdStorage)!
    .borrow<&ColdStorage.Vault{ColdStorage.PublicVault}>()!

  return publicVault.getKey()
}