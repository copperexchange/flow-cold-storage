import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"

pub fun main(address: Address): Bool {
  let vault = getAccount(address)
    .getCapability(/public/flowTokenColdStakingStorage)
  if vault == nil {
    return false
  }
  return true
}
