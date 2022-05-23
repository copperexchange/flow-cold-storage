import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import ColdStorage from "../contracts/ColdStorage.cdc"

pub fun main(address: Address): [String] {
    let v2ContractVault = getAccount(address)
      .getCapability(/public/flowTokenColdStakingStorage)!
      .borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>()!
    return v2ContractVault.getNodeDelegatorNodeIDs()
}
