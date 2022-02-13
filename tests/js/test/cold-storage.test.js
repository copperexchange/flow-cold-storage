import path from "path";
import {
	emulator,
	init,
	mintFlow,
	getFlowBalance,
} from "flow-js-testing";
import {config} from "@onflow/config"
import {
	deployColdStorage,
	setupColdStorageVault,
	transferTokens,
	getBalance, getSequence,
} from "../src/cold-storage";

import { signWithPrivateKey, sigAlgos, hashAlgos } from "../src/crypto"

import { toUFix64, getAccountA, getAccountB } from "../src/common";

// We need to set timeout for a higher number, because some transactions might take up some time
jest.setTimeout(10000);

const privateKeyB = "102f7a8cb22083d1f44ea6f2e7df19c620689f7944408e421873a254c0749c37"
const publicKeyB = "727369698d62f2ec2f0ea4788192824c682e9a576d1d4769978a336b801b42735f2dbae2e722baa3d4d26ca276a1e4dccc3e5b1f52a39324a722372cca5bf114"

// The UserDomainTag is the prefix of all signed user space payloads.
//
// Before hashing and signing the message, the wallet must add a specified DOMAIN TAG.
//
// UserDomainTag is currently "FLOW-V0.0-user"
//
// A domain tag is encoded as UTF-8 bytes, right padded to a total length of 32 bytes, prepended to the message.
const userDomainTag = Buffer.from("464c4f572d56302e302d75736572000000000000000000000000000000000000", "hex")

function toBigEndianBytes(number, bits) {
	return Buffer.from(
		BigInt(number).toString(16).padStart(bits / 4, "0"),
		"hex",
	)
}

describe("ColdStorage", () => {
	// Instantiate emulator and path to Cadence files
	beforeEach(async () => {
		const basePath = path.resolve(__dirname, "../../../");
		const port = 8083;
		await init(basePath, port);
		config().put("PRIVATE_KEY", "8e3983030d2af1fa01c078241ad7f699d492e0239247f38d5a96cb959e436531")
		return emulator.start(port, false);
	});

	// Stop emulator, so it could be restarted
	afterEach(async () => {
		return emulator.stop();
	});

	it("should be able to create an empty ColdStorage.Vault", async () => {
		const contractName = await deployColdStorage();
		console.log("deployed", contractName)

		const accountA = await getAccountA();
		await mintFlow(accountA, "10.0");
		const vault = await setupColdStorageVault(accountA, publicKeyB)
		console.log("accountB vault", vault)
	});

	it("should be able to create a ColdStorage.Vault and fund with FLOW", async () => {
		await deployColdStorage();

		const accountA = await getAccountA();
		await mintFlow(accountA, "10.0");

		const [settedUp] = await setupColdStorageVault(accountA, publicKeyB)

		const { data: { address } } = settedUp.events.find((event) => event.type == 'flow.AccountCreated')

		await mintFlow(address, "10.0");

		const [balance, _] = await getBalance(address);


		expect(balance).toBe(toUFix64(10.0));
	});

	it("should be able to transfer FLOW from a ColdStorage.Vault", async () => {
		await deployColdStorage();

		const recipient = await getAccountA();
		await mintFlow(recipient, "10.0");

		const [settedUp] = await setupColdStorageVault(recipient, publicKeyB)

		const { data: { address } } = settedUp.events.find((event) => event.type == 'flow.AccountCreated')

		await mintFlow(address, "10.0");

		const [balance,] = await getBalance(address);
		const [sequence,] = await getSequence(address);

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

		const [balanceB,] = await getBalance(address);
		expect(balanceB).toBe(toUFix64(5.0));
	});
});