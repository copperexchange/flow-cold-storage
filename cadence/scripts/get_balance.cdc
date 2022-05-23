import ColdStorage from "../contracts/ColdStorage.cdc"
import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"

pub fun main(address: Address): UFix64 {
    let v2ContractVault = getAccount(address)
      .getCapability(/public/flowTokenColdStakingStorage)!
    if let v2ContractCapability = v2ContractVault.borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>() {
      return v2ContractCapability.getBalance()
    } else {
      let v1ContractCapability = getAccount(address)
          .getCapability(/public/flowTokenColdStorage)!
          .borrow<&ColdStorage.Vault{ColdStorage.PublicVault}>()!
      return v1ContractCapability
          .getBalance()
    }
}
