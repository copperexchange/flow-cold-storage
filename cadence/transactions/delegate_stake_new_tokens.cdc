import Crypto

import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"

transaction(senderAddress: Address, contractAddress: Address, amount: UFix64, seqNo: UInt64, signatureA: String) {

  let pendingDelegateStakeNewTokens: @ColdStakingStorage.PendingDelegateStakeNewTokens

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
      stakeOperation: ColdStakingStorage.StakingOption.delegateNewTokens,
      sigSet: signatureSet,
    )

    self.pendingDelegateStakeNewTokens <- publicVault.prepareDelegateStakeNewTokens(request: request)
  }

  execute {
    self.pendingDelegateStakeNewTokens.execute()
    destroy self.pendingDelegateStakeNewTokens
  }
}
