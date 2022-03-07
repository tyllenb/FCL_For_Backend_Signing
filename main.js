// run this script with `node main.js`
// see your transaction at `https://testnet.flowscan.org/transaction/YOUR_TX_ID`

const fcl = require("@onflow/fcl");
const t = require("@onflow/types");
const { MINT_NFT } = require("./cadence/tx/MINT_NFT.tx.js");

const {authorizationFunction, authorizationFunctionProposer} = require("./helpers/authorization.js");

var description = ""
var image = ""
var name = ""
var series = ""
var quantity = 100
fcl.config()
    .put("accessNode.api", "https://testnet.onflow.org");


const sendTx = async () => {
  const transactionId = await fcl.send([
    fcl.transaction(MINT_NFT),
    fcl.args([
      fcl.arg(description, t.String),
      fcl.arg(image, t.String),
      fcl.arg(name, t.String),
      fcl.arg(series, t.String),
      fcl.arg(quantity, t.UInt64),
    ]),
    fcl.proposer(authorizationFunctionProposer),
    fcl.payer(authorizationFunction),
    fcl.authorizations([authorizationFunction]),
    fcl.limit(9999),
  ]).then(fcl.decode);

  console.log(transactionId);
}

sendTx()




