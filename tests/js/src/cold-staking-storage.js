import {
    deployContractByName,
    sendTransaction,
    executeScript,
    getContractAddress
} from "flow-js-testing";
import { getAccountA} from "./common";


export const deployColdStakingStorage = async () => {
    const FungibleToken = await getContractAddress("FungibleToken");
    const FlowToken = await getContractAddress("FlowToken");
    const FlowIDTableStaking = await getContractAddress("FlowIDTableStaking");

    const addressMap = {
        FungibleToken,
        FlowToken,
        FlowIDTableStaking,
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
    const args = [publicKey];
    const signers = [account];

    const transactionResult = await sendTransaction({ name, args, signers });
    if (transactionResult[1] == null) {
        console.log("Setup Staking Vault: ", JSON.stringify(transactionResult))
    } else {
        console.log("Error: ", transactionResult[1])
    }
    return transactionResult;
};

export const transferTokens = async (sender, recipient, amount, seqNo, signatureB) => {
    const name = "transfer_funds";
    const args = [sender, recipient, amount, seqNo, signatureB];
    const accountA = await getAccountA();
    const signers = [accountA];

    const transactionResult = await sendTransaction({ name, args, signers });
    if (transactionResult[1] == null) {
        console.log("Transfer Tokens: ", JSON.stringify(transactionResult))
    } else {
        console.log("Error: ", transactionResult[1])
    }
    return transactionResult;
};

export const delegateStakeNewTokens = async (sender, contractAddress, amount, seqNo, nodeID, signatureB) => {
    const name = "delegate_stake_new_tokens";
    const args = [sender, contractAddress, amount, seqNo, nodeID, signatureB];
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

export const delegateStakeGeneralRequest = async (sender, contractAddress, amount, seqNo, nodeID, stakingOption, signatureB) => {
    const name = "delegate_stake_general_request";
    const args = [sender, contractAddress, amount, seqNo, nodeID, stakingOption, signatureB];
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

export const migrateAccountToNewContract = async (sender, transferAmount, stakeAmount, seqNo, signatureA, nodeID) => {
    const name = "migrate_account_to_new_contract";
    const args = [sender, transferAmount, stakeAmount, seqNo, nodeID, signatureA];
    const accountA = await getAccountA();
    const signers = [accountA];
    let sendTransactionResult = await sendTransaction({ name, args, signers });
    if (sendTransactionResult[1] == null) {
        console.log("Migrate Account to New Contract: ", JSON.stringify(sendTransactionResult))
    } else {
        console.log("Error: ", sendTransactionResult[1])
    }
    return sendTransactionResult;
};

export const getBalance = async (account) => {
    const name = "get_balance";
    const args = [account];

    let executeScriptResult = await executeScript({ name, args });
    if (executeScriptResult[1] == null) {
        console.log("Execute Balance: ", JSON.stringify(executeScriptResult))
    } else {
        console.log("Error: ", executeScriptResult[1])
    }
    return executeScriptResult;
};

export const getSequence = async (account) => {
    const name = "get_sequence";
    const args = [account];

    return executeScript({ name, args });
};

export const getNodeDelegatorIds = async (account) => {
    const name = "get_node_delegator_ids";
    const args = [account];

    return executeScript({ name, args });
};

export const StakingOption = {
    delegateNewTokens: 0,
    delegateUnstakedTokens: 1,
    delegateRewardedTokens: 2,
    requestUnstaking: 3,
    withdrawUnstakedTokens: 4,
    withdrawRewardedTokens: 5,
}
