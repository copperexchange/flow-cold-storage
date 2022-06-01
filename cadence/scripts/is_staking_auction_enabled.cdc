import FlowIDTableStaking from "../contracts/TestFlowIDTableStaking.cdc"

pub fun main(): Bool {
  return FlowIDTableStaking.stakingEnabled()
}
