import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"
import ColdStakingStorage from "../contracts/ColdStakingStorage.cdc"
import FlowIDTableStaking from "../contracts/FlowIDTableStaking.cdc"

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

    let accountKey = ColdStakingStorage.Key(
      publicKey: key.publicKey.publicKey,
      signatureAlgorithm: key.publicKey.signatureAlgorithm,
      hashAlgorithm: key.hashAlgorithm,
    )

    let coldVault <- ColdStakingStorage.createVault(
      address: account.address,
      key: accountKey,
      contents: <-flowVault,
      nodeDelegators: <- {}
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
