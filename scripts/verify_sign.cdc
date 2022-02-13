import Crypto

pub fun main(rawPublic: String, wei: UFix64, sign: String, signedData: String): Bool {
  let keyList = Crypto.KeyList()
  let rawPublicKeys = [rawPublic]
  let weights = [wei]
  let signatures = [sign]
  var i = 0
  for rawPublicKey in rawPublicKeys {
    keyList.add(
      PublicKey(
        publicKey: rawPublicKey.decodeHex(),
        signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1
      ),
      hashAlgorithm: HashAlgorithm.SHA2_256,
      weight: weights[i],
    )
    i = i + 1
  }

  log(keyList)

  let signatureSet: [Crypto.KeyListSignature] = []
  var j = 0
  for signature in signatures {
    signatureSet.append(
      Crypto.KeyListSignature(
        keyIndex: j,
        signature: signature.decodeHex()
      )
    )
    j = j + 1
  }
  log(signatureSet)
//return true
  return keyList.verify(
    signatureSet: signatureSet,
    signedData: signedData.decodeHex(),
  )
}