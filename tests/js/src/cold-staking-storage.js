import {
    deployContractByName,
    sendTransaction,
    executeScript,
    getContractAddress
} from "flow-js-testing";
import { getAccountA } from "./common";


export const deployColdStakingStorage = async () => {
    const FungibleToken = await getContractAddress("FungibleToken");
    const FlowToken = await getContractAddress("FlowToken");
    const TestFlowIDTableStaking = await getContractAddress("TestFlowIDTableStaking");

    const addressMap = {
        FungibleToken,
        FlowToken,
        TestFlowIDTableStaking,
    };
    const deployed = await deployContractByName({ name: "ColdStakingStorage", addressMap: addressMap });
    if (deployed[1] == null) {
        console.log("Deployed ColdStakingStorage: ", JSON.stringify(deployed))
    } else {
        console.log("Error: ", deployed[1])
    }
    return await getContractAddress("ColdStakingStorage");
};

export const setupColdStakingStorageVault = async (account, publicKey) => {
    const name = "setup_staking_vault";
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

export const registerNewDelegator = async (sender, seqNo, signatureB, nodeID) => {
    const name = "register_new_delegator";
    const args = [sender, seqNo, nodeID, signatureB];
    const accountA = await getAccountA();
    const signers = [accountA];
    let transactionResult = await sendTransaction({ name, args, signers });
    if (transactionResult[1] == null) {
        console.log("Registered New Delegator: ", JSON.stringify(transactionResult))
    } else {
        console.log("Error: ", transactionResult[1])
    }
    return transactionResult;
};

export const delegateStakeNewTokens = async (sender, contractAddress, amount, seqNo, signatureB) => {
    const name = "delegate_stake_new_tokens";
    const args = [sender, contractAddress, amount, seqNo, signatureB];
    const accountA = await getAccountA();
    const signers = [accountA];
    let transactionResult = await sendTransaction({ name, args, signers });
    if (transactionResult[1] == null) {
        console.log("Delegate Stake New Tokens: ", JSON.stringify(transactionResult))
    } else {
        console.log("Error: ", transactionResult[1])
    }
    return transactionResult;
};

export const delegateStakeGeneralRequest = async (sender, contractAddress, amount, seqNo, stakingOption, signatureB) => {
    const name = "delegate_stake_general_request";
    const args = [sender, contractAddress, amount, seqNo, stakingOption, signatureB];
    const accountA = await getAccountA();
    const signers = [accountA];
    let transactionResult = await sendTransaction({ name, args, signers });
    if (transactionResult[1] == null) {
        console.log("Stake General Request: ", JSON.stringify(transactionResult))
    } else {
        console.log("Error: ", transactionResult[1])
    }
    return transactionResult;
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

export const StakingOption = {
    delegateNewTokens: 0,
    delegateUnstakedTokens: 1,
    delegateRewardedTokens: 2,
    requestUnstaking: 3,
    withdrawUnstakedTokens: 4,
    withdrawRewardedTokens: 55,
}
