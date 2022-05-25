import FlowIDTableStaking from "../contracts/ColdStakingStorage.cdc"

pub fun main(): Bool {
  return FlowIDTableStaking.stakingEnabled()
}
