import FungibleToken from 0x9a0766d93b6608b7
import FlowToken from 0x7e60df042a9c0868
import ColdStorage from 0x8b7e0b1056e8f550

transaction(publicKey: String) {
  prepare(signer: AuthAccount) {
    let account = AuthAccount(payer: signer)

    log(account.storageUsed)
    log(account.storageCapacity)

    account.keys.add(
        publicKey: PublicKey(
          publicKey: publicKey.decodeHex(),
          signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1,
        ),
        hashAlgorithm: HashAlgorithm.SHA2_256,
        weight: 1000.0,
    )

    let flowVault <- FlowToken.createEmptyVault()

    let key = account.keys.get(keyIndex: 0) ?? panic("Invalid key in account")

    let accountKey = ColdStorage.Key(
      publicKey: key.publicKey.publicKey,
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