import {
    deployContractByName,
    sendTransaction,
    executeScript,
    getContractAddress
} from "flow-js-testing";
import { getAccountA, getAccountNode } from "./common";


export const deployFlowStakingContracts = async () => {
    const deployed = await deployContractByName({ name: "TestFlowIDTableStaking" });
    if (deployed[1] == null) {
        console.log("Deployed TestFlowIDTableStaking: ", JSON.stringify(deployed))
    } else {
        console.log("Error: ", deployed[1])
    }
    return await getContractAddress("TestFlowIDTableStaking");
};

export const setupFlowStakingNode = async (nodeId) => {
    const name = "setup_testing_node";
    const args = [nodeId];
    const nodeAccount = await getAccountNode();
    const signers = [nodeAccount];
    let sendTransactionResult = await sendTransaction({ name, args, signers });
    if (sendTransactionResult[1] == null) {
        console.log("Deployed TestFlowIDTableStaking: ", JSON.stringify(sendTransactionResult))
    } else {
        console.log("Error: ", sendTransactionResult[1])
    }
    return sendTransactionResult;
};
