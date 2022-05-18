import Crypto
import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import ColdStorage from "../contracts/ColdStorage.cdc"
import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import TestFlowIDTableStaking from "../contracts/TestFlowIDTableStaking.cdc"

transaction(senderAddress: Address, amount: UFix64, seqNo: UInt64, signatureA: String, nodeID: String) {
  prepare(signer: AuthAccount) {
    let newAccount = AuthAccount(payer: signer)
    let oldAccount = getAccount(senderAddress)
    let oldAccountVaultRef = oldAccount
                          .getCapability(/public/flowTokenColdStorage)!
                          .borrow<&ColdStorage.Vault{ColdStorage.PublicVault}>()
                           ?? panic("Unable to borrow old account vault")

    let key = oldAccount.keys.get(keyIndex: 0) ?? panic("Invalid key in account")
    newAccount.keys.add(
        publicKey: key.publicKey,
        hashAlgorithm: key.hashAlgorithm,
        weight: key.weight,
    )

    let flowVault <- FlowToken.createEmptyVault()
    let coldStorageKey = oldAccountVaultRef.getKey()
    let nodeDelegator <- TestFlowIDTableStaking.registerNewDelegator(nodeID: nodeID)

    let accountKey = ColdStakingStorage.Key(
      publicKey: key.publicKey.publicKey,
      signatureAlgorithm: key.publicKey.signatureAlgorithm,
      hashAlgorithm: key.hashAlgorithm,
    )
    let coldStakingVault <- ColdStakingStorage.createVault(
      address: newAccount.address,
      key: accountKey,
      contents: <-flowVault,
      nodeDelegator: <-nodeDelegator,
    )

    let signatureSet = Crypto.KeyListSignature(
        keyIndex: 0,
        signature: signatureA.decodeHex()
      )

    let request = ColdStorage.WithdrawRequest(
      senderAddress: oldAccount.address,
      recipientAddress: signer.address,
      amount: amount,
      seqNo: seqNo,
      sigSet: signatureSet,
    )

    let pendingWithdrawal <- oldAccountVaultRef.prepareWithdrawal(request: request)
    pendingWithdrawal.execute(fungibleTokenReceiverPath: /public/flowTokenReceiver)

    let vaultRef = signer.borrow<&FlowToken.Vault>(from: /storage/flowTokenVault)
			?? panic("Could not borrow reference to the signer's Vault!")

    coldStakingVault.deposit(from: <-vaultRef.withdraw(amount: amount))

    destroy pendingWithdrawal

    newAccount.save(<-coldStakingVault, to: /storage/flowTokenColdStakingStorage)
    newAccount.link<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>(/public/flowTokenColdStakingStorage, target: /storage/flowTokenColdStakingStorage)

    newAccount.unlink(/public/flowTokenReceiver)
    newAccount.link<&{FungibleToken.Receiver}>(/public/flowTokenReceiver,target: /storage/flowTokenColdStorage)
  }

}
