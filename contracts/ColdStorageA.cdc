import Crypto

import FungibleToken from "./FungibleToken.cdc"
import FlowToken from "./FlowToken.cdc"

pub contract ColdStorageA {

  pub struct Key {
    pub let publicKey: String
    // pub let signatureAlgorithm: SignatureAlgorithm
    // pub let hashAlgorithm: HashAlgorithm
    pub let weight: UFix64

    init(
      publicKey: String,
      // signatureAlgorithm: SignatureAlgorithm,
      // hashAlgorithm: HashAlgorithm,
      weight: UFix64,
    ) {
      self.publicKey = publicKey
      // self.signatureAlgorithm = signatureAlgorithm
      // self.hashAlgorithm = hashAlgorithm
      self.weight = weight
    }
  }

  pub struct interface ColdStorageRequest {
    pub var sigSet: String
    pub var seqNo: UInt64
    pub var senderAddress: Address

    pub fun signableBytes(): [UInt8]
  }

  pub struct WithdrawRequest: ColdStorageRequest {
    pub var sigSet: String
    pub var seqNo: UInt64

    pub var senderAddress: Address
    pub var recipientAddress: Address
    pub var amount: UFix64

    init(
      senderAddress: Address,
      recipientAddress: Address,
      amount: UFix64,
      seqNo: UInt64,
      sigSet: String,
    ) {
      self.senderAddress = senderAddress
      self.recipientAddress = recipientAddress
      self.amount = amount

      self.seqNo = seqNo
      self.sigSet = sigSet
    }

    pub fun signableBytes(): [UInt8] {
      let senderAddress = self.senderAddress.toBytes()
      let recipientAddressBytes = self.recipientAddress.toBytes()
      let amountBytes = self.amount.toBigEndianBytes()
      let seqNoBytes = self.seqNo.toBigEndianBytes()

      return senderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
    }
  }

  pub resource PendingWithdrawal {

    access(self) var pendingVault: @FungibleToken.Vault
    access(self) var request: WithdrawRequest

    init(pendingVault: @FungibleToken.Vault, request: WithdrawRequest) {
      self.pendingVault <- pendingVault
      self.request = request
    }

    pub fun execute(fungibleTokenReceiverPath: PublicPath) {
      var pendingVault <- FlowToken.createEmptyVault()
      self.pendingVault <-> pendingVault

      let recipient = getAccount(self.request.recipientAddress)
      let receiver = recipient
        .getCapability(fungibleTokenReceiverPath)!
        .borrow<&{FungibleToken.Receiver}>()
        ?? panic("Unable to borrow receiver reference for recipient")

      receiver.deposit(from: <- pendingVault)
    }

    destroy (){
      pre {
        self.pendingVault.balance == 0.0 as UFix64
      }
      destroy self.pendingVault
    }
  }

  pub resource interface PublicVault {
    pub fun getSequenceNumber(): UInt64

    pub fun getBalance(): UFix64

    pub fun getKeys(): [Key]

    pub fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal

    pub fun showSignableMessage(
        address: Address,
        recipientAddress: Address,
        amount: UFix64,
        seqNo: UInt64
    ): [UInt8]

  }

  pub resource Vault : FungibleToken.Receiver, PublicVault {
    access(self) var address: Address
    access(self) var keys: [Key]
    access(self) var contents: @FungibleToken.Vault
    access(self) var seqNo: UInt64

    pub fun deposit(from: @FungibleToken.Vault) {
      self.contents.deposit(from: <-from)
    }

    pub fun getSequenceNumber(): UInt64 {
        return self.seqNo
    }

    pub fun getBalance(): UFix64 {
      return self.contents.balance
    }

    pub fun getKeys(): [Key] {
      return self.keys
    }

    pub fun showSignableMessage(
        address: Address,
        recipientAddress: Address,
        amount: UFix64,
        seqNo: UInt64
    ): [UInt8] {
        let senderAddress = address.toBytes()
        let recipientAddressBytes = recipientAddress.toBytes()
        let amountBytes = amount.toBigEndianBytes()
        let seqNoBytes = seqNo.toBigEndianBytes()

        return senderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
    }

    pub fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal {
      pre {
        self.isValidSignature(request: request)
      }
      post {
        self.seqNo == request.seqNo + UInt64(1)
      }

      self.incrementSequenceNumber()

      return <- create PendingWithdrawal(pendingVault: <- self.contents.withdraw(amount: request.amount), request: request)
    }

    access(self) fun incrementSequenceNumber(){
      self.seqNo = self.seqNo + UInt64(1)
    }

    access(self) fun isValidSignature(request: {ColdStorageA.ColdStorageRequest}): Bool {
      pre {
        self.seqNo == request.seqNo
        self.address == request.senderAddress
      }

      return ColdStorageA.validateSignature(
        keys: self.keys,
        signatureSet: request.sigSet,
        message: request.signableBytes()
      )
    }

    init(address: Address, keys: [Key], contents: @FungibleToken.Vault) {
      self.keys = keys
      self.seqNo = UInt64(0)
      self.contents <- contents
      self.address = address
    }

    destroy() {
      destroy self.contents
    }
  }

  pub fun createVault(
    address: Address,
    keys: [Key],
    contents: @FungibleToken.Vault,
  ): @Vault {
    return <- create Vault(address: address, keys: keys, contents: <- contents)
  }

  pub fun validateSignature(
    keys: [Key],
    signatureSet: String,
    message: [UInt8],
  ): Bool {

 log("AJAHAHAHAHAHAHAH")
 log(keys[0])
    let pk = PublicKey(
                       publicKey: keys[0].publicKey.decodeHex(),
                       signatureAlgorithm: SignatureAlgorithm.ECDSA_secp256k1
                     )

    return pk.verify(
    signature: signatureSet.decodeHex(),
    signedData: message,
    domainSeparationTag: "FLOW-V0.0-user",
    hashAlgorithm: HashAlgorithm.SHA2_256)
  }
}