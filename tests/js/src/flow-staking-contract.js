import {
    sendTransaction,
    getContractAddress, getContractCode, deployContract
} from "flow-js-testing";
import { getAccountNode } from "./common";


export const deployFlowStakingContracts = async () => {
    const nodeAccount = await getAccountNode();
    const contractCode = await getContractCode({ name: "TestFlowIDTableStaking", addressMap: {} })
    const deployed = await deployContract({ name: "FlowIDTableStaking", to: nodeAccount, code: contractCode });
    if (deployed[1] == null) {
        console.log("Deployed test FlowIDTableStaking: ", JSON.stringify(deployed))
    } else {
        console.log("Error: ", deployed[1])
    }
    return await getContractAddress("FlowIDTableStaking");
};

export const setupFlowStakingNode = async (nodeId) => {
    const name = "testing/setup_testing_node";
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
