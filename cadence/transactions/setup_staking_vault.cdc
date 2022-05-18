import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import TestFlowIDTableStaking from "../contracts/TestFlowIDTableStaking.cdc"

transaction(publicKey: String, signatureAlgorithmRaw: UInt8, hashAlgorithmRaw: UInt8) {
  prepare(signer: AuthAccount) {
    let account = AuthAccount(payer: signer)

    log(account.storageUsed)
    log(account.storageCapacity)

    let signatureAlgorithm = SignatureAlgorithm(rawValue: signatureAlgorithmRaw) ?? panic("invalid signature algorithm")
    let hashAlgorithm = HashAlgorithm(rawValue: hashAlgorithmRaw) ?? panic("invalid hash algorithm")

    account.keys.add(
        publicKey: PublicKey(
          publicKey: publicKey.decodeHex(),
          signatureAlgorithm: signatureAlgorithm,
        ),
        hashAlgorithm: hashAlgorithm,
        weight: 1000.0,
    )

    let flowVault <- FlowToken.createEmptyVault()

    let key = account.keys.get(keyIndex: 0) ?? panic("Invalid key in account")

    let accountKey = ColdStakingStorage.Key(
      publicKey: key.publicKey.publicKey,
      signatureAlgorithm: key.publicKey.signatureAlgorithm,
      hashAlgorithm: key.hashAlgorithm,
    )

    let nilNodeDelegator: @TestFlowIDTableStaking.NodeDelegator? <- nil
    let coldVault <- ColdStakingStorage.createVault(
      address: account.address,
      key: accountKey,
      contents: <-flowVault,
      nodeDelegator: <-nilNodeDelegator, // Do not register node delegator
    )

    // save the new cold vault to storage
    account.save(<-coldVault, to: /storage/flowTokenColdStakingStorage)

    // ability to get the sequence number of the vault
    account.link<&ColdStakingStorage.Vault{ColdStakingStorage.PublicVault}>(
      /public/flowTokenColdStakingStorage,
      target: /storage/flowTokenColdStakingStorage
    )

    account.unlink(/public/flowTokenReceiver)

    account.link<&{FungibleToken.Receiver}>(
      /public/flowTokenReceiver,
      target: /storage/flowTokenColdStakingStorage
    )
  }
}
