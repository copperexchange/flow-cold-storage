import ColdStorageA from "../contracts/ColdStorageA.cdc"

pub fun main(address: Address): Capability {
  let publicVault = getAccount(address)
    .getCapability(/public/flowTokenColdStorage)!

  return publicVault
}