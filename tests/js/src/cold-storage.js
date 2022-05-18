import {
	deployContractByName,
	mintFlow,
	sendTransaction,
	executeScript,
	getAccountAddress,
	getContractAddress
} from "flow-js-testing";
import { getAccountA } from "./common";

export const deployColdStorage = async () => {
	const deployed = await deployContractByName({  name: "ColdStorage" });
	console.log(JSON.stringify(deployed))
	return await getContractAddress("ColdStorage");
};

export const setupColdStorageVault = async (account, publicKey) => {
	const name = "cold-storage/setup_vault";
	const args = [publicKey, 2, 1];
	const signers = [account];

	return sendTransaction({ name, args, signers });
};

export const transferColdStorageTokens = async (sender, recipient, amount, seqNo, signatureB) => {
	const name = "cold-storage/transfer_funds";
	const args = [sender, recipient, amount, seqNo, signatureB];
	const accountA = await getAccountA();
	const signers = [accountA];
	return sendTransaction({ name, args, signers });
};

export const getColdStorageBalance = async (account) => {
	const name = "cold-storage/get_balance";
	const args = [account];

	return executeScript({ name, args });
};

export const getColdStorageSequence = async (account) => {
	const name = "cold-storage/get_sequence";
	const args = [account];

	return executeScript({ name, args });
};
