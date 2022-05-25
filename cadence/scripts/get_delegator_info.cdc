import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import FlowIDTableStaking from "../contracts/FlowIDTableStaking.cdc"

pub fun main(address: Address): [FlowIDTableStaking.DelegatorInfo] {
  let v2ContractVault = getAccount(address)
    .getCapability(/public/flowTokenColdStakingStorage)!
    .borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>()
    ?? panic("Could not borrow reference to cold storage staking contract")

  let delegatorInfo: [FlowIDTableStaking.DelegatorInfo] = []
  let nodeIDs = v2ContractVault.getNodeDelegatorNodeIDs()
  for nodeID in nodeIDs {
    let delegatorID = v2ContractVault.getNodeDelegatorID(nodeID: nodeID)
    delegatorInfo.append(FlowIDTableStaking.DelegatorInfo(nodeID: nodeID, delegatorID: delegatorID))
  }

  return delegatorInfo
}
