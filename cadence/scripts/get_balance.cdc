import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"

pub fun main(address: Address): UFix64 {
  let publicVault = getAccount(address)
    .getCapability(/public/flowTokenColdStakingStorage)!
    .borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>()!

  return publicVault.getBalance()
}
