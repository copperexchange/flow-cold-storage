# cadence-cold-storage

this contract is used to incapsulate signature verification onchain to be able to transfer funds without TTL between signing and sending to the network

setting up vault and resource associating with as also as adding public key included in setup_vault.cdc transaction  

By setting up account we create special resource called ColdStorage defined in /public/flowTokenColdStorage and link deposits into it

then to make a transfer we use transfer funds transaction to be broadcasted to network by service account

## Developer
### Tests
Tests are made using the 
To run the tests you need to install [Flow CLI](https://docs.onflow.org/flow-cli/install/).

Start the Flow emulator in tests/js  with`flow emulator -v`

Run the tests with `npm run test`
