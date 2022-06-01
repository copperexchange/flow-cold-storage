import Crypto

import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import FlowIDTableStaking from "../contracts/FlowIDTableStaking.cdc"

transaction(senderAddress: Address, seqNo: UInt64, nodeID: String, signatureA: String) {

  prepare(signer: AuthAccount) {
    let sender = getAccount(senderAddress)

    let publicVault = sender
      .getCapability(/public/flowTokenColdStakingStorage)!
      .borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>()!

    let signatureSet = Crypto.KeyListSignature(
        keyIndex: 0,
        signature: signatureA.decodeHex()
      )

    let request = ColdStakingStorage.NodeDelegatorChangeRequest(
        senderAddress: senderAddress,
        seqNo: seqNo,
        nodeID: nodeID,
        signature: signatureSet,
      )

    let newNodeDelegator <- FlowIDTableStaking.registerNewDelegator(nodeID: nodeID)
    publicVault.updateNodeDelegator(request: request, newNodeDelegator: <-newNodeDelegator)
  }
}
