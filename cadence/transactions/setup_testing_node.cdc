import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import TestFlowIDTableStaking from "../contracts/TestFlowIDTableStaking.cdc"

transaction(id: String) {
  prepare(signer: AuthAccount) {
    let flowVault <- FlowToken.createEmptyVault()

    let nodeRecord <- TestFlowIDTableStaking.addNodeRecord(
        id: id,
        role: 1,
        networkingAddress: "dummy",
        networkingKey: "dummy",
        stakingKey: "dummy",
        tokensCommitted: <- flowVault
    )
    signer.save(<-nodeRecord, to: /storage/FlowIDTableStakingStorage)
  }
}
