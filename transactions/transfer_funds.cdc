import Crypto
import ColdStorage from 0xd6c19aa81a451d7c

transaction(senderAddress: Address, recipientAddress: Address, amount: UFix64, seqNo: UInt64, signatureA: String) {

  let pendingWithdrawal: @ColdStorage.PendingWithdrawal

  prepare(signer: AuthAccount) {
    let sender = getAccount(senderAddress)

    let publicVault = sender
      .getCapability(/public/flowTokenColdStorage)!
      .borrow<&ColdStorage.Vault{ColdStorage.PublicVault}>()!

    let signatureSet = [
      Crypto.KeyListSignature(
        keyIndex: 0,
        signature: signatureA.decodeHex()
      )
    ]

    let request = ColdStorage.WithdrawRequest(
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