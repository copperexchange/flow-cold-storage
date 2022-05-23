import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import ColdStorage from "../contracts/ColdStorage.cdc"

pub fun main(address: Address): UInt64 {
    let v2ContractVault = getAccount(address)
      .getCapability(/public/flowTokenColdStakingStorage)!
    if let v2ContractCapability = v2ContractVault.borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>() {
      return v2ContractCapability.getSequenceNumber()
    } else {
      let v1ContractCapability = getAccount(address)
          .getCapability(/public/flowTokenColdStorage)!
          .borrow<&ColdStorage.Vault{ColdStorage.PublicVault}>()!
      return v1ContractCapability
          .getSequenceNumber()
    }
}
