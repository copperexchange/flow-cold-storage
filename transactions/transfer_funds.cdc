import Crypto

import ColdStorage from 0x8b7e0b1056e8f550

transaction(senderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, signatureA: String) {

  let pendingWithdrawal: @ColdStorage.PendingWithdrawal

  prepare(signer: AuthAccount) {
    let sender = getAccount(senderAddress)

    let publicVault = sender
      .getCapability(/public/flowTokenColdStorage)!
      .borrow<&ColdStorage.Vault{ColdStorage.PublicVault}>()!

    let request = ColdStorage.WithdrawRequest(
      senderAddress: senderAddress,
      recipientAddress: recipientAddress,
      amount: amount,
      seqNo: seqNo,
      sigSet: signatureA.decodeHex(),
    )

    self.pendingWithdrawal <- publicVault.prepareWithdrawal(request: request)
  }

  execute {
    self.pendingWithdrawal.execute(fungibleTokenReceiverPath: /public/flowTokenReceiver)
    destroy self.pendingWithdrawal
  }
}