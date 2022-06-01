import Crypto

import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"

transaction(senderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, signatureA: String) {

  let pendingWithdrawal: @ColdStakingStorage.PendingWithdrawal

  prepare(signer: AuthAccount) {
    let sender = getAccount(senderAddress)

    let publicVault = sender
      .getCapability(/public/flowTokenColdStakingStorage)!
      .borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>()!

    let signatureSet =
      Crypto.KeyListSignature(
        keyIndex: 0,
        signature: signatureA.decodeHex()
      )

    let request = ColdStakingStorage.WithdrawRequest(
      senderAddress: senderAddress,
      recipientAddress: recipientAddress,
      amount: amount,
      seqNo: seqNo,
      sigSet: signatureSet,
    )

    self.pendingWithdrawal <- publicVault.prepareWithdrawal(request: request)
  }

  execute {
    self.pendingWithdrawal.execute(fungibleTokenReceiverPath: /public/flowTokenReceiver)
    destroy self.pendingWithdrawal
  }
}
