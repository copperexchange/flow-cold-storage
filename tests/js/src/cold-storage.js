import { deployContractByName, mintFlow, sendTransaction, executeScript } from "flow-js-testing";
import { getAccountA } from "./common";

export const deployColdStorage = async () => {
	const accountA = await getAccountA();
	await mintFlow(accountA, "10.0");

	return deployContractByName({ to: accountA, name: "ColdStorage" });
};

export const setupColdStorageVault = async (account, publicKey) => {
	const name = "setup_vault";
	const args = [publicKey];
	const signers = [account];

	return sendTransaction({ name, args, signers });
};

export const transferTokens = async (sender, recipient, amount, seqNo, signatureB) => {
	const name = "transfer_funds";
	const args = [sender, recipient, amount, seqNo, signatureB];

	return sendTransaction({ name, args });
};

export const getBalance = async (account) => {
	const name = "get_balance";
	const args = [account];

	return executeScript({ name, args });
};