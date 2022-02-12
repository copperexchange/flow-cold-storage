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
	return await getContractAddress("ColdStorage");
};

export const deployColdStorageA = async () => {
	console.log("deployContractByName({  name: \"ColdStorageA\" })")
	const deployed = await deployContractByName({  name: "ColdStorageA" });
	console.log(deployed)
	return await getContractAddress("ColdStorageA");
};

export const setupColdStorageVault = async (account, publicKey) => {
	const name = "setup_vault";
	const args = [publicKey, 2, 1];
	const signers = [account];

	return sendTransaction({ name, args, signers });
};

export const transferTokens = async (sender, recipient, amount, seqNo, signatureB) => {
	const name = "transfer_funds";
	const args = [sender, recipient, amount, seqNo, signatureB];
	const accountA = await getAccountA();
	const signers = [accountA];
	return sendTransaction({ name, args, signers });
};

export const getBalance = async (account) => {
	const name = "get_balance";
	const args = [account];

	return executeScript({ name, args });
};
export const getSequence = async (account) => {
	const name = "get_sequence";
	const args = [account];

	return executeScript({ name, args });
};