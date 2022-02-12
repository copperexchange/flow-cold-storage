import Crypto

import ColdStorageA from "../contracts/ColdStorageA.cdc"

transaction(senderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, signatureA: String) {

  let pendingWithdrawal: @ColdStorageA.PendingWithdrawal

  prepare(signer: AuthAccount) {
    let sender = getAccount(senderAddress)

    let publicVault = sender
      .getCapability(/public/flowTokenColdStorage)!
      .borrow<&ColdStorageA.Vault{ColdStorageA.PublicVault}>()!

    let request = ColdStorageA.WithdrawRequest(
      senderAddress: senderAddress,
      recipientAddress: recipientAddress,
      amount: amount,
      seqNo: seqNo,
      sigSet: signatureA
    )

    self.pendingWithdrawal <- publicVault.prepareWithdrawal(request: request)
  }

  execute {
    self.pendingWithdrawal.execute(fungibleTokenReceiverPath: /public/flowTokenReceiver)
    destroy self.pendingWithdrawal
  }
}