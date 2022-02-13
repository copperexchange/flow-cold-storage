              transaction(keyA: [UInt8]) {
                prepare(signer: AuthAccount) {
                  let acct = AuthAccount(payer: signer)
                  acct.addPublicKey(keyA)
                }
              }