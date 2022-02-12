import FungibleToken from "../contracts/FungibleToken.cdc"
import FlowToken from "../contracts/FlowToken.cdc"
import ColdStorageA from "../contracts/ColdStorageA.cdc"

transaction(publicKey: String) {
  prepare(signer: AuthAccount) {
    let account = AuthAccount(payer: signer)

    log(account.storageUsed)
    log(account.storageCapacity)

    account.keys.add(
        publicKey: PublicKey(
          publicKey: publicKey.decodeHex(),
          //signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1,
          signatureAlgorithm: SignatureAlgorithm.ECDSA_P256,
        ),
        //hashAlgorithm: HashAlgorithm.SHA2_256,
        hashAlgorithm: HashAlgorithm.SHA3_256,
        weight: 1000.0,
    )

    let flowVault <- FlowToken.createEmptyVault()

    let key = account.keys.get(keyIndex: 0) ?? panic("Invalid key in account")

    log(key.publicKey)

    let accountKey = ColdStorageA.Key(
      publicKey: publicKey,
      weight: 1000.0
    )


    let coldVault <- ColdStorageA.createVault(
      address: account.address,
      keys: [accountKey],
      contents: <-flowVault,
    )

    // save the new cold vault to storage
    account.save(<-coldVault, to: /storage/flowTokenColdStorage)


    // ability to get the sequence number of the vault
    account.link<&ColdStorageA.Vault{ColdStorageA.PublicVault}>(
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