import Crypto

import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"

transaction(senderAddress: Address, contractAddress: Address, amount: UFix64, seqNo: UInt64, stakeOperation: UInt8, signatureA: String) {

  prepare(signer: AuthAccount) {
    let sender = getAccount(senderAddress)

    let publicVault = sender
      .getCapability(/public/flowTokenColdStakingStorage)!
      .borrow<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>()!

    let signatureSet = Crypto.KeyListSignature(
        keyIndex: 0,
        signature: signatureA.decodeHex()
      )

    let request = ColdStakingStorage.DelegateStakeRequest(
      senderAddress: senderAddress,
      contractAddress: contractAddress,
      amount: amount,
      seqNo: seqNo,
      stakeOperation: ColdStakingStorage.StakeOperation(rawValue: stakeOperation)!,
      sigSet: signatureSet,
    )

    publicVault.executeDelegateStakeGeneralRequest(request: request)
  }
}
