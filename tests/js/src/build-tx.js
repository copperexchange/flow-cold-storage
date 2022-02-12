
const {hashAlgos, sigAlgos, signWithPrivateKey} = require("./crypto")


function toBigEndianBytes(number, bits) {
	return Buffer.from(
		BigInt(number).toString(16).padStart(bits / 4, "0"),
		"hex",
	)
}

const userDomainTag = Buffer.from("464c4f572d56302e302d75736572000000000000000000000000000000000000", "hex")
const privateKey = "80c7c2a326dbf0c3bac8d047ee9923f4000fce6a209ef7839abf4ca2f443d637"
const sender = "0x7e1242144b7369d8"
const recipient = "0x4c0baa55880a3a15"
const amount = "5.0"
const seqNo = "0"

const message = Buffer.concat(
	[
		userDomainTag,
		Buffer.from(sender.slice(2), "hex"),
		Buffer.from(recipient.slice(2), "hex"),
		toBigEndianBytes("500000000", 64), // amount
		toBigEndianBytes("0", 64),         // seqNo
	]
).toString("hex");

const signature = signWithPrivateKey(
	privateKey,
	sigAlgos.ECDSA_secp256k1,
	hashAlgos.SHA2_256,
	message,
);

console.log(signature)