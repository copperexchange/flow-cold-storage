import Crypto

import FungibleToken from "./FungibleToken"
import FlowToken from "./FlowToken"
import FlowIDTableStaking from "./FlowIDTableStaking"

pub contract ColdStakingStorage {
  pub event ColdStakingDelegateNewTokens(nodeID: String, address: Address, amount: UFix64)
  pub event ColdStakingDelegateUnstakedTokens(nodeID: String, address: Address, amount: UFix64)
  pub event ColdStakingDelegateRewardedTokens(nodeID: String, address: Address, amount: UFix64)
  pub event ColdStakingRequestUnstaking(nodeID: String, address: Address, amount: UFix64)
  pub event ColdStakingWithdrawUnstakedTokens(nodeID: String, address: Address, amount: UFix64)
  pub event ColdStakingWithdrawRewardedTokens(nodeID: String, address: Address, amount: UFix64)

  pub enum StakeOperation: UInt8 {
      pub case delegateNewTokens
      pub case delegateUnstakedTokens
      pub case delegateRewardedTokens
      pub case requestUnstaking
      pub case withdrawUnstakedTokens
      pub case withdrawRewardedTokens
  }

  pub struct Key {
    pub let publicKey: [UInt8]
    pub let signatureAlgorithm: UInt8
    pub let hashAlgorithm: UInt8

    init(
      publicKey: [UInt8],
      signatureAlgorithm: SignatureAlgorithm,
      hashAlgorithm: HashAlgorithm
    ) {
      self.publicKey = publicKey
      self.signatureAlgorithm = signatureAlgorithm.rawValue
      self.hashAlgorithm = hashAlgorithm.rawValue
    }
  }

  pub struct interface ColdStakingStorageRequest {
    pub var signature: Crypto.KeyListSignature
    pub var seqNo: UInt64
    pub var senderAddress: Address

    pub fun signableBytes(): [UInt8]
  }

  pub struct WithdrawRequest: ColdStakingStorageRequest {
    pub var signature: Crypto.KeyListSignature
    pub var seqNo: UInt64

    pub var senderAddress: Address
    pub var recipientAddress: Address
    pub var amount: UFix64

    init(
      senderAddress: Address,
      recipientAddress: Address,
      amount: UFix64,
      seqNo: UInt64,
      signature: Crypto.KeyListSignature,
    ) {
      self.senderAddress = senderAddress
      self.recipientAddress = recipientAddress
      self.amount = amount

      self.seqNo = seqNo
      self.signature = signature
    }

    pub fun signableBytes(): [UInt8] {
      let senderAddress = self.senderAddress.toBytes()
      let recipientAddressBytes = self.recipientAddress.toBytes()
      let amountBytes = self.amount.toBigEndianBytes()
      let seqNoBytes = self.seqNo.toBigEndianBytes()

      return senderAddress.concat(recipientAddressBytes).concat(amountBytes).concat(seqNoBytes)
    }
  }

  pub struct DelegateStakeRequest: ColdStakingStorageRequest {
    pub var signature: Crypto.KeyListSignature
    pub var seqNo: UInt64

    pub var senderAddress: Address
    pub var contractAddress: Address
    pub var amount: UFix64
    pub var nodeID: String
    pub var stakeOperation: StakeOperation

    init(
      senderAddress: Address,
      contractAddress: Address,
      amount: UFix64,
      seqNo: UInt64,
      nodeID: String,
      stakeOperation: StakeOperation,
      signature: Crypto.KeyListSignature,
    ) {
      self.senderAddress = senderAddress
      self.contractAddress = contractAddress
      self.amount = amount
      self.seqNo = seqNo
      self.nodeID = nodeID
      self.stakeOperation = stakeOperation
      self.signature = signature
    }

    pub fun signableBytes(): [UInt8] {
      let senderAddress = self.senderAddress.toBytes()
      let contractAddressBytes = self.contractAddress.toBytes()
      let amountBytes = self.amount.toBigEndianBytes()
      let stakeOperationBytes = self.stakeOperation.rawValue.toBigEndianBytes()
      let seqNoBytes = self.seqNo.toBigEndianBytes()
      let nodeIDBytes = self.nodeID.utf8

      return senderAddress
            .concat(contractAddressBytes)
            .concat(amountBytes)
            .concat(nodeIDBytes)
            .concat(stakeOperationBytes)
            .concat(seqNoBytes)
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

  pub resource PendingDelegateStakeNewTokens {

    access(self) var pendingVault: @FungibleToken.Vault
    access(self) var request: DelegateStakeRequest
    access(self) var nodeDelegatorRef: &FlowIDTableStaking.NodeDelegator

    init(pendingVault: @FungibleToken.Vault, request: DelegateStakeRequest, nodeDelegatorRef: &FlowIDTableStaking.NodeDelegator) {
      self.pendingVault <- pendingVault
      self.request = request
      self.nodeDelegatorRef = nodeDelegatorRef
    }

    pub fun execute() {
      var pendingVault <- FlowToken.createEmptyVault()
      self.pendingVault <-> pendingVault

      emit ColdStakingDelegateNewTokens(nodeID: self.request.nodeID, address: self.request.senderAddress, amount: self.request.amount)
      self.nodeDelegatorRef.delegateNewTokens(from: <-pendingVault)
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

    pub fun getKey(): Key

    pub fun getNodeDelegatorID(nodeID: String): UInt32

    pub fun getNodeDelegatorNodeIDs(): [String]

    pub fun prepareWithdrawal(request: WithdrawRequest): @PendingWithdrawal

    pub fun prepareDelegateStakeNewTokens(request: DelegateStakeRequest): @PendingDelegateStakeNewTokens

    pub fun executeDelegateStakeGeneralRequest(request: DelegateStakeRequest)
  }

  pub resource Vault : FungibleToken.Receiver, PublicVault {
    access(self) var address: Address
    access(self) var key: Key
    access(self) var contents: @FungibleToken.Vault
    access(self) var seqNo: UInt64
    access(self) var nodeDelegators: @{String: FlowIDTableStaking.NodeDelegator}

    pub fun deposit(from: @FungibleToken.Vault) {
      self.contents.deposit(from: <-from)
    }

    pub fun getSequenceNumber(): UInt64 {
        return self.seqNo
    }

    pub fun getBalance(): UFix64 {
      return self.contents.balance
    }

    pub fun getKey(): Key {
      return self.key
    }

    pub fun getNodeDelegatorID(nodeID: String): UInt32 {
      let nodeDelegator <- self.nodeDelegators.remove(key: nodeID) ?? panic("Unable to get Node Delegator for given node id")
      let id = nodeDelegator.id
      let emptyNodeDelegator <- self.nodeDelegators.insert(key:nodeID, <- nodeDelegator)
      destroy emptyNodeDelegator
      return id
    }

    pub fun getNodeDelegatorNodeIDs(): [String] {
      return self.nodeDelegators.keys
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

    pub fun prepareDelegateStakeNewTokens(request: DelegateStakeRequest): @PendingDelegateStakeNewTokens {
      pre {
        self.isValidSignature(request: request)
      }
      post {
        self.seqNo == request.seqNo + UInt64(1)
      }
      self.incrementSequenceNumber()

      if let nodeDelegator <- self.nodeDelegators.remove(key: request.nodeID) {
        let nodeDelegatorRef = &nodeDelegator as? &FlowIDTableStaking.NodeDelegator
        let emptyNodeDelegator <- self.nodeDelegators.insert(key:request.nodeID, <- nodeDelegator)
        destroy emptyNodeDelegator
        return <- create PendingDelegateStakeNewTokens(pendingVault: <- self.contents.withdraw(amount: request.amount), request: request, nodeDelegatorRef: nodeDelegatorRef)
      } else {
        let nodeDelegatorRef = self.registerNewDelegator(nodeID: request.nodeID)
        return <- create PendingDelegateStakeNewTokens(pendingVault: <- self.contents.withdraw(amount: request.amount), request: request, nodeDelegatorRef: nodeDelegatorRef)
      }
    }

    pub fun executeDelegateStakeGeneralRequest(request: DelegateStakeRequest) {
      pre {
        self.isValidSignature(request: request)
      }
      post {
        self.seqNo == request.seqNo + UInt64(1)
      }

      let nodeDelegatorRef = self.borrowNodeDelegator(nodeID: request.nodeID)
      self.incrementSequenceNumber()
      switch request.stakeOperation {
        case StakeOperation.delegateUnstakedTokens:
          emit ColdStakingDelegateUnstakedTokens(nodeID: request.nodeID, address: self.address, amount: request.amount)
          nodeDelegatorRef.delegateUnstakedTokens(amount: request.amount)
        case StakeOperation.delegateRewardedTokens:
          emit ColdStakingDelegateRewardedTokens(nodeID: request.nodeID, address: self.address, amount: request.amount)
          nodeDelegatorRef.delegateRewardedTokens(amount: request.amount)
        case StakeOperation.requestUnstaking:
          emit ColdStakingRequestUnstaking(nodeID: request.nodeID, address: self.address, amount: request.amount)
          nodeDelegatorRef.requestUnstaking(amount: request.amount)
        case StakeOperation.withdrawUnstakedTokens:
          emit ColdStakingWithdrawUnstakedTokens(nodeID: request.nodeID, address: self.address, amount: request.amount)
          self.deposit(from: <-nodeDelegatorRef.withdrawUnstakedTokens(amount: request.amount))
        case StakeOperation.withdrawRewardedTokens:
          emit ColdStakingWithdrawRewardedTokens(nodeID: request.nodeID, address: self.address, amount: request.amount)
          self.deposit(from: <-nodeDelegatorRef.withdrawRewardedTokens(amount: request.amount))
        default:
          panic("Unknown Staking request")
      }
    }

    access(self) fun borrowNodeDelegator(nodeID: String): &FlowIDTableStaking.NodeDelegator {
      if let nodeDelegator <- self.nodeDelegators.remove(key: nodeID) {
        let nodeDelegatorRef = &nodeDelegator as? &FlowIDTableStaking.NodeDelegator
        let emptyNodeDelegator <- self.nodeDelegators.insert(key:nodeID, <- nodeDelegator)
        destroy emptyNodeDelegator
        return nodeDelegatorRef
      }
      panic("Unable to get Node delegator!")
    }

    access(self) fun incrementSequenceNumber(){
      self.seqNo = self.seqNo + UInt64(1)
    }

    access(account) fun registerNewDelegator(nodeID: String): &FlowIDTableStaking.NodeDelegator {
      let newNodeDelegator <- FlowIDTableStaking.registerNewDelegator(nodeID: nodeID)
      let nodeDelegatorRef = &newNodeDelegator as? &FlowIDTableStaking.NodeDelegator
      let oldNodeDelegator <- self.nodeDelegators.insert(key: nodeID, <- newNodeDelegator)
      destroy oldNodeDelegator
      return nodeDelegatorRef
    }

    access(self) fun isValidSignature(request: {ColdStakingStorage.ColdStakingStorageRequest}): Bool {
      pre {
        self.seqNo == request.seqNo
        self.address == request.senderAddress
      }

      return ColdStakingStorage.validateSignature(
        key: self.key,
        signature: request.signature,
        message: request.signableBytes()
      )
    }

    init(address: Address, key: Key, contents: @FungibleToken.Vault, nodeDelegators: @{String: FlowIDTableStaking.NodeDelegator}) {
      self.key = key
      self.seqNo = UInt64(0)
      self.contents <- contents
      self.address = address
      self.nodeDelegators <- nodeDelegators
    }

    destroy() {
      destroy self.contents
      destroy self.nodeDelegators
    }
  }

  pub fun createVault(
    address: Address,
    key: Key,
    contents: @FungibleToken.Vault,
    nodeDelegators: @{String: FlowIDTableStaking.NodeDelegator}
  ): @Vault {
    return <- create Vault(address: address, key: key, contents: <- contents, nodeDelegators: <- nodeDelegators)
  }

  pub fun validateSignature(
    key: Key,
    signature: Crypto.KeyListSignature,
    message: [UInt8],
  ): Bool {
    let keyList = Crypto.KeyList()

    let signatureAlgorithm = SignatureAlgorithm(rawValue: key.signatureAlgorithm) ?? panic("invalid signature algorithm")
    let hashAlgorithm = HashAlgorithm(rawValue: key.hashAlgorithm)  ?? panic("invalid hash algorithm")

    keyList.add(
      PublicKey(
        publicKey: key.publicKey,
        signatureAlgorithm: signatureAlgorithm,
      ),
      hashAlgorithm: hashAlgorithm,
      weight: 1000.0,
    )

    return keyList.verify(
      signatureSet: [signature],
      signedData: message
    )
  }
}
