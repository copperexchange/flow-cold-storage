import path from "path";
import {
    emulator,
    init,
    mintFlow,
    getContractAddress,
    getFlowBalance, sendTransaction,
} from "flow-js-testing";
import { config } from "@onflow/config"
import {
    deployColdStakingStorage,
    setupColdStakingStorageVault,
    transferTokens,
    getColdStorageStakingBalance,
    getColdStorageStakingSequence,
    registerNewDelegator,
    delegateStakeNewTokens,
    StakingOption,
    delegateStakeGeneralRequest,
    migrateAccountToNewContract,
} from "../src/cold-staking-storage";
import {
    deployFlowStakingContracts, setupFlowStakingNode
} from "../src/flow-staking-contract";

import { signWithPrivateKey, sigAlgos, hashAlgos } from "../src/crypto"

import { toUFix64, getAccountA, getAccountB, getAccountNode } from "../src/common";
import { deployColdStorage, setupColdStorageVault, getColdStorageBalance, getColdStorageSequence } from "../src/cold-storage";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(10000);

const privateKeyB = "102f7a8cb22083d1f44ea6f2e7df19c620689f7944408e421873a254c0749c37"
const publicKeyB = "727369698d62f2ec2f0ea4788192824c682e9a576d1d4769978a336b801b42735f2dbae2e722baa3d4d26ca276a1e4dccc3e5b1f52a39324a722372cca5bf114"

// The UserDomainTag is the prefix of all signed user space payloads.
// Before hashing and signing the message, the wallet must add a specified DOMAIN TAG.
// UserDomainTag is currently "FLOW-V0.0-user"
// A domain tag is encoded as UTF-8 bytes, right padded to a total length of 32 bytes, prepended to the message.
const userDomainTag = Buffer.from("464c4f572d56302e302d75736572000000000000000000000000000000000000", "hex")

function toBigEndianBytes(number, bits) {
    return Buffer.from(
        BigInt(number).toString(16).padStart(bits / 4, "0"),
        "hex",
    )
}

async function setupEmulator(port) {
    const basePath = path.resolve(__dirname, "../../../cadence");
    await init(basePath, port);
    config().put("PRIVATE_KEY", "8e3983030d2af1fa01c078241ad7f699d492e0239247f38d5a96cb959e436531")
    return emulator.start(port, true);
}

function tearDownEmulator() {
    return emulator.stop();
}

describe("TestFlowIDTableStaking deployment", () => {
    beforeEach(async () => {
        return await setupEmulator(8080);
    });

    afterEach(async () => {
        return tearDownEmulator();
    });

    it("should be able to deploy the test flow staking contract ", async () => {
        const contractName = await deployFlowStakingContracts();
        expect(contractName).not.toBeNull();
    });

    it("should be able to register a new node ", async () => {
        const contractName = await deployFlowStakingContracts();
        expect(contractName).not.toBeNull();
        const result = await setupFlowStakingNode("1")
        expect(result[1]).toBeNull();   // Check there was no error
    });
});

describe("ColdStakingStorage deployment", () => {
    beforeEach(async () => {
        return await setupEmulator(8081);
    });

    afterEach(async () => {
        return tearDownEmulator();
    });

    it("should be able to create an empty ColdStakingStorage.Vault", async () => {
        await deployFlowStakingContracts();
        const contractName = await deployColdStakingStorage();
        console.log("deployed", contractName)
        expect(contractName).not.toBeNull();

        const accountA = await getAccountA();
        await mintFlow(accountA, "10.0");
        const vault = await setupColdStakingStorageVault(accountA, publicKeyB)
        console.log("accountB vault", vault)
        expect(vault).not.toBeNull();
    });

    it("should be able to create a ColdStakingStorage.Vault and fund with FLOW", async () => {
        await deployFlowStakingContracts();
        await deployColdStakingStorage();

        const accountA = await getAccountA();
        await mintFlow(accountA, "10.0");

        const [setUpTransactionResult] = await setupColdStakingStorageVault(accountA, publicKeyB)

        const { data: { address } } = setUpTransactionResult.events.find((event) => event.type == 'flow.AccountCreated')

        await mintFlow(address, "10.0");

        const [balance, _] = await getColdStorageStakingBalance(address);


        expect(balance).toBe(toUFix64(10.0));
    });
});

describe("ColdStakingStorage transaction", () => {
    beforeEach(async () => {
        return await setupEmulator(8083);
    });

    afterEach(async () => {
        return tearDownEmulator();
    });

    it("should be able to transfer FLOW from a ColdStakingStorage.Vault", async () => {
        await deployFlowStakingContracts();
        await deployColdStakingStorage();

        const recipient = await getAccountA();
        await mintFlow(recipient, "10.0");

        const [settedUp] = await setupColdStakingStorageVault(recipient, publicKeyB)

        const { data: { address } } = settedUp.events.find((event) => event.type == 'flow.AccountCreated')

        await mintFlow(address, "10.0");

        const [balance,] = await getColdStorageStakingBalance(address);
        const [sequence,] = await getColdStorageStakingSequence(address);

        console.log('settled account for vault: ', address, balance, sequence)

        const sender = address
        const amount = "5.0"
        const seqNo = sequence

        const message = Buffer.concat(
            [
                userDomainTag,
                Buffer.from(sender.slice(2), "hex"),
                Buffer.from(recipient.slice(2), "hex"),
                toBigEndianBytes("500000000", 64), // amount
                toBigEndianBytes("0", 64),         // seqNo
            ]
        ).toString("hex");

        const signatureB = signWithPrivateKey(
            privateKeyB,
            sigAlgos.ECDSA_secp256k1,
            hashAlgos.SHA2_256,
            message,
        );

        console.log('message, sign: ', message, signatureB)

        const result = await transferTokens(
            sender, recipient, amount, seqNo, signatureB
        )
        console.log('transferTokens', JSON.stringify(result))

        const [balanceA,] = await getFlowBalance(recipient);
        expect(balanceA).toBe(toUFix64(15.00000000));

        const [balanceB,] = await getColdStorageStakingBalance(address);
        expect(balanceB).toBe(toUFix64(5.0));
    });
});

describe("ColdStakingStorage staking", () => {
    const nodeID = "1";
    let address;

    beforeEach(async () => {
        await setupEmulator(8084);
        address = await setupVaultAccount();
        return  setupFlowStakingNode(nodeID)
    });

    afterEach(async () => {
        return tearDownEmulator();
    });

    async function setupVaultAccount() {
        await deployFlowStakingContracts();
        await deployColdStakingStorage();
        const recipient = await getAccountA();
        await mintFlow(recipient, "10.0");
        const [setupTransaction] = await setupColdStakingStorageVault(recipient, publicKeyB)
        const { data: { address } } = setupTransaction.events.find((event) => event.type === 'flow.AccountCreated')
        return address
    }

    function createSignedMessageToRegister(address, nodeID) {
        const message = Buffer.concat([
                userDomainTag,
                Buffer.from(address.slice(2), "hex"),
                Buffer.from(nodeID, "utf8"),
                toBigEndianBytes("0", 64),         // seqNo
            ]).toString("hex");
        return signWithPrivateKey(
            privateKeyB,
            sigAlgos.ECDSA_secp256k1,
            hashAlgos.SHA2_256,
            message,
        );
    }

    function createSignedMessageForStakeRequest(address, contractAddress, amount, stakingOption, seqNo) {
        const message = Buffer.concat([
                userDomainTag,
                Buffer.from(address.slice(2), "hex"),
                Buffer.from(contractAddress.slice(2), "hex"),
                toBigEndianBytes((amount*100_000_000).toString(), 64),
                toBigEndianBytes(stakingOption, 8),
                toBigEndianBytes(seqNo, 64),         // seqNo
            ]).toString("hex");
        return signWithPrivateKey(
            privateKeyB,
            sigAlgos.ECDSA_secp256k1,
            hashAlgos.SHA2_256,
            message,
        );
    }

    it("should be able to register to staking node", async () => {
        const [sequence,] = await getColdStorageStakingSequence(address);
        const signatureB = createSignedMessageToRegister(address, nodeID);

        const result = await registerNewDelegator(address, sequence, signatureB, nodeID)
        expect(result[1]).toBeNull();   // Check there was no error
    });

    it("should be able to delegate stake tokens to a node", async () => {
        let [sequence,] = await getColdStorageStakingSequence(address);
        const signatureBRegister = createSignedMessageToRegister(address, nodeID);
        await registerNewDelegator(address, sequence, signatureBRegister, nodeID)
        const contractAddress = await getContractAddress("TestFlowIDTableStaking");
        await mintFlow(address, "10.0");
        [sequence,] = await getColdStorageStakingSequence(address);
        let amount = 5;
        const signatureBStakeRequest = createSignedMessageForStakeRequest(address, contractAddress, amount, StakingOption.delegateNewTokens, sequence);
        const result = await delegateStakeNewTokens(address, contractAddress, amount, sequence, signatureBStakeRequest)
        const { data: { nodeID: nodeIDRegistered, delegatorID: delegatorIDRegistered, amount: amountStakedRegistered } } = result[0].events.find((event) => event.type.includes('TestFlowIDTableStaking.DelegatorTokensCommitted'))
        expect(nodeIDRegistered).toBe(nodeID);
        expect(delegatorIDRegistered).toBe(1);
        expect(parseInt(amountStakedRegistered)).toBe(amount);
        const [balanceB,] = await getColdStorageStakingBalance(address);
        expect(balanceB).toBe(toUFix64(5.0));
    });

    it("should be able to undelegate tokens", async () => {
        let [sequence,] = await getColdStorageStakingSequence(address);
        const signatureBRegister = createSignedMessageToRegister(address, nodeID);
        await registerNewDelegator(address, sequence, signatureBRegister, nodeID)
        const contractAddress = await getContractAddress("TestFlowIDTableStaking");
        await mintFlow(address, "10.0");
        [sequence,] = await getColdStorageStakingSequence(address);
        let amount = 5;
        const signatureBStakeRequest = createSignedMessageForStakeRequest(address, contractAddress, amount, StakingOption.delegateUnstakedTokens, sequence);
        const result = await delegateStakeGeneralRequest(address, contractAddress, amount, sequence, StakingOption.delegateUnstakedTokens, signatureBStakeRequest)
        const { data: { nodeID: nodeIDRegistered, delegatorID: delegatorIDRegistered, amount: amountStakedRegistered } } = result[0].events.find((event) => event.type.includes('TestFlowIDTableStaking.DelegatorTokensCommitted'))
        expect(nodeIDRegistered).toBe(nodeID);
        expect(delegatorIDRegistered).toBe(1);
        expect(parseInt(amountStakedRegistered)).toBe(amount);
        const [balanceB,] = await getColdStorageStakingBalance(address);
        expect(balanceB).toBe(toUFix64(10.0));
    });

    it("should be able to withdraw unstaked tokens", async () => {
        let [sequence,] = await getColdStorageStakingSequence(address);
        const signatureBRegister = createSignedMessageToRegister(address, nodeID);
        await registerNewDelegator(address, sequence, signatureBRegister, nodeID)
        const contractAddress = await getContractAddress("TestFlowIDTableStaking");
        await mintFlow(address, "10.0");
        [sequence,] = await getColdStorageStakingSequence(address);
        let amount = 5;
        const signatureBStakeRequest = createSignedMessageForStakeRequest(address, contractAddress, amount, StakingOption.withdrawUnstakedTokens, sequence);
        const result = await delegateStakeGeneralRequest(address, contractAddress, amount, sequence, StakingOption.withdrawUnstakedTokens, signatureBStakeRequest)
        const { data: { nodeID: nodeIDRegistered, delegatorID: delegatorIDRegistered, amount: amountStakedRegistered } } = result[0].events.find((event) => event.type.includes('TestFlowIDTableStaking.DelegatorUnstakedTokensWithdrawn'))
        expect(nodeIDRegistered).toBe(nodeID);
        expect(delegatorIDRegistered).toBe(1);
        expect(parseInt(amountStakedRegistered)).toBe(amount);
        const [balanceB,] = await getColdStorageStakingBalance(address);
        expect(balanceB).toBe(toUFix64(15.0));
    });
});

describe("ColdStakingStorage migration", () => {
    let oldAccountAddress;
    let serviceAccount;
    const nodeID = "1";

    beforeEach(async () => {
        await setupEmulator(8085);
        serviceAccount = await getAccountA();
        oldAccountAddress = await setupOldVaultAccount();
        await deployFlowStakingContracts();
        await deployColdStakingStorage();
        return setupFlowStakingNode(nodeID)
    });

    afterEach(async () => {
        return tearDownEmulator();
    });

    async function setupOldVaultAccount() {
        await deployColdStorage();
        await mintFlow(serviceAccount, "1.0");
        const [setupTransaction] = await setupColdStorageVault(serviceAccount, publicKeyB)
        const { data: { address } } = setupTransaction.events.find((event) => event.type === 'flow.AccountCreated')
        return address;
    }

    function createSignedMessageToTransfer(sender, recipient, amount, sequence) {
        const message = Buffer.concat([
                userDomainTag,
                Buffer.from(sender.slice(2), "hex"),
                Buffer.from(recipient.slice(2), "hex"),
                toBigEndianBytes((amount*100_000_000).toString(), 64),
                toBigEndianBytes(sequence, 64),
            ]
        ).toString("hex");
        return signWithPrivateKey(
            privateKeyB,
            sigAlgos.ECDSA_secp256k1,
            hashAlgos.SHA2_256,
            message,
        );
    }

    it("should be able to migrate account to account with new contract", async () => {
        await mintFlow(oldAccountAddress, "10.0");
        const [sequence,] = await getColdStorageSequence(oldAccountAddress);
        const [startingBalAsString, ] = await getColdStorageBalance(oldAccountAddress);
        const startingBalance = parseFloat(startingBalAsString);
        const signatureTransfer = createSignedMessageToTransfer(oldAccountAddress, serviceAccount, startingBalance, sequence);
        const result = await migrateAccountToNewContract(oldAccountAddress, startingBalance, sequence, signatureTransfer, nodeID);
        const { data: { address: createdAddress } } = result[0].events.find((event) => event.type === 'flow.AccountCreated')

        const [oldAccountCurrentBalance,] = await getColdStorageBalance(oldAccountAddress);
        expect(oldAccountCurrentBalance).toBe(toUFix64(0.0));
        const [createdAddressCurrentBalance,] = await getColdStorageStakingBalance(createdAddress);
        expect(createdAddressCurrentBalance).toBe(toUFix64(10.0));
    });
});
