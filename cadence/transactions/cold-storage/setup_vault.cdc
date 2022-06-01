import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import ColdStorage from "../contracts/ColdStorage.cdc"

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

    let accountKey = ColdStorage.Key(
      publicKey: key.publicKey.publicKey,
      signatureAlgorithm: key.publicKey.signatureAlgorithm,
      hashAlgorithm: key.hashAlgorithm,
    )


    let coldVault <- ColdStorage.createVault(
      address: account.address,
      key: accountKey,
      contents: <-flowVault,
    )

    // save the new cold vault to storage
    account.save(<-coldVault, to: /storage/flowTokenColdStorage)


    // ability to get the sequence number of the vault
    account.link<&ColdStorage.Vault{ColdStorage.PublicVault}>(
      /public/flowTokenColdStorage,
      target: /storage/flowTokenColdStorage
    )

    account.unlink(/public/flowTokenReceiver)

    account.link<&{FungibleToken.Receiver}>(
      /public/flowTokenReceiver,
      target: /storage/flowTokenColdStorage
    )
  }
}
