
const express = require('express');
const app = express();
bodyParser = require('body-parser');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));


var ca_config = require('./config/ca_config.json');
var Fabric_Client = require('fabric-client');
var Fabric_CA_Client = require('fabric-ca-client');

var path = require('path');
var util = require('util');
var os = require('os');
var fs = require('fs');

var fabric_client = new Fabric_Client();
global.fabric_ca_client = null
var admin_user= null
var member_user = null
var store_path = path.join(__dirname, 'hfc-key-store');

var channel = null
var peer = null;
var order = null;
var tx_id = null;


app.get('/', (req, res) => {
	console.log(userStore)
	res.send("Hello");

  
 });

app.post('/usermanage/user/', (req,res) => {
	const userId = req.body.userId || '';
	var userSecret = '';

	if(!userId.length){
		return res.status(400).json({error: 'Incorrenct name'});
	}

	fabric_ca_client.register({enrollmentID: userId, affiliation: 'org1.department1', role:'client'}, admin_user).then((secret) => {
		console.log("Successfully registered " + userId + " - sercret : " + secret);
		userSecret = secret;

		return fabric_ca_client.enroll({enrollmentID: userId, enrollmentSecret: secret});
	}).then((enrollment) => {
		return fabric_client.createUser(
			{username: userId,
			mspid : ca_config.mspId,
     cryptoContent: { privateKeyPEM: enrollment.key.toBytes(), signedCertPEM: enrollment.certificate }
		}); 
	}).then((user) => {
		member_user = user;

		return fabric_client.setUserContext(member_user);
	}).then(() => {
		console.log(userId + ' was successfully registered and enrolled and is ready to intreact with the fabric network');
		
		return res.status(201).json({enrollmentID:userId, enrollmentSecret:userSecret});
	}).catch((err) => {
    console.error('Failed to register: ' + err);
        if(err.toString().indexOf('Authorization') > -1) {
                console.error('Authorization failures may be caused by having admin credentials from a previous CA instance.\n' +
                'Try again after deleting the contents of the store directory '+store_path);
        }
	});
});


app.post('/usermanage/user/enroll', (req,res) => {
	const userID= req.body.enrollmentID|| '';
  const userSecret= req.body.enrollmentSecret|| '';

	console.log(userID, userSecret);

	if(!userID.length){
		return res.status(400).json({error: "Incorrect enrollmentID"});
	}

	if(!userSecret.length){
		return res.status(400).json({error: "Incorrect enrollmentSecret"});
	}
	

//	fabric_ca_client.enroll({ enrollmentID: userID, enrollmentSecret: userSecret}).then((enrollment) => {
//		return fabric_client.createUser(
//        {username: userId,
//         mspid : ca_config.mspId,
//         cryptoContent: { privateKeyPEM: enrollment.key.toBytes(), signedCertPEM: enrollment.certificate }
//      	});
//	}).then((user) => {
//		member_user = user;
//		return fabric_client.setUserContext(member_user);
//	}).then(() => {
//		console.log(userId + ' was successfully enrolled and is ready to intreact with the fabric network');
//    return res.status(201).json({enrollmentID:userId, enrollmentSecret:userSecret});
//
//	}).catch((err) => {
//		console.error('Failed to register: ' + err);
//        if(err.toString().indexOf('Authorization') > -1) {
//                console.error('Authorization failures may be caused by having admin credentials from a previous CA instance.\n' +
//                'Try again after deleting the contents of the store directory '+store_path);
//					return res.status(401).json({err:'Authorization failures may be caused by having admin credentials from a previous CA instance.\n Try again after deleting the contents of the store directory '+store_path });
//        }
//	});


	fabric_client.getUserContext(userID, true).then((user_from_store) => {
		if(user_from_store && user_from_store.isEnrolled()){
			console.log("Successfully loaded user from persistence");
			return res.status(200).json("Successfully loaded user from persistence");
		} else {
			console.log("failed to get user");
			return res.status(400).json("Failed to get user");
		}
	});

});

app.post("/transaction/product", (req,res) => {
	
	var userID = req.body.enrollmentID || '';
  var productName = req.body.productName || '';
  var qty = req.body.qty || '';
  var owner = "store1";
  var chaincodeId = ca_config.chaincodeid;
	var channelName = ca_config.channel_name;

	fabric_client.getUserContext(userID, true).then((user_from_store) => {
	  if(user_from_store && user_from_store.isEnrolled()){
	    console.log("Successfully loaded user from persistence");
			member_user = user_from_store;
    } else {
      console.log("failed to get user");
			return res.status(400).json("Failed to get user");
    }
		
		tx_id = fabric_client.newTransactionID();
		var request = {
			chaincodeId : chaincodeId,
			fcn: 'registProducts',
			args: [productName, qty, owner],
			chainId: channelName,
			txId: tx_id
		};

		return channel.sendTransactionProposal(request);
  }).then((results) => {
		var proposalResponses = results[0];
    var proposal = results[1];
    let isProposalGood = false;
    if (proposalResponses && proposalResponses[0].response &&
         proposalResponses[0].response.status === 200) {
           isProposalGood = true;
           console.log('Transaction proposal was good');
    } else {
  	  console.error('Transaction proposal was bad');
    }
		if (isProposalGood) {
  	  console.log(util.format(
        'Successfully sent Proposal and received ProposalResponse: Status - %s, message - "%s"',
         proposalResponses[0].response.status, proposalResponses[0].response.message));

			var request = {
				proposalResponses: proposalResponses,
        proposal: proposal
      };

      var transaction_id_string = tx_id.getTransactionID(); //Get the transaction ID string to be used by the event processing
      var promises = [];

      let peerserverCert = fs.readFileSync(path.join(__dirname, '../../crypto-config/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt'));
      var sendPromise = channel.sendTransaction(request);
      promises.push(sendPromise);
			
			let event_hub = fabric_client.newEventHub();
      event_hub.setPeerAddr(ca_config.event_url,{
          'pem': Buffer.from(peerserverCert).toString(),
          'ssl-target-name-override': "peer0.store1.mymarket.com",
        });

      let txPromise = new Promise((resolve, reject) => {
      	let handle = setTimeout(() => {
        	event_hub.disconnect();
          resolve({event_status : 'TIMEOUT'}); //we could use reject(new Error('Trnasaction did not complete within 30 seconds'));
        }, 3000);
        event_hub.connect();
        event_hub.registerTxEvent(transaction_id_string, (tx, code) => {
        	clearTimeout(handle);
          event_hub.unregisterTxEvent(transaction_id_string);
          event_hub.disconnect();

          var return_status = {event_status : code, tx_id : transaction_id_string};
          	if (code !== 'VALID') {
            	console.error('The transaction was invalid, code = ' + code);
              resolve(return_status); // we could use reject(new Error('Problem with the tranaction, event status ::'+code));
            } else {
              console.log('The transaction has been committed on peer ' + event_hub._ep._endpoint.addr);
              resolve(return_status);
            }
         }, (err) => {
           reject(new Error('There was a problem with the eventhub ::'+err));
         });
       });
       promises.push(txPromise);

       return Promise.all(promises);
		} else {
   		console.error('Failed to send Proposal or receive valid response. Response null or status is not 200. exiting...');
    	 throw new Error('Failed to send Proposal or receive valid response. Response null or status is not 200. exiting...');
    }

	}).then((results) => {
		var isSuccess = false;
		var isValid = false;
		console.log('Send transaction promise and event listener promise have completed');
        // check the results in the order the promises were added to the promise all list
    if (results && results[0] && results[0].status === 'SUCCESS') {
						isSuccess = true;
            console.log('Successfully sent transaction to the orderer.');
    } else {
            console.error('Failed to order the transaction. Error code: ' + response.status);
    }

    if(results && results[1] && results[1].event_status === 'VALID') {
						isValid = true;
            console.log('Successfully committed the change to the ledger by the peer');
    } else {
            console.log('Transaction failed to be committed to the ledger due to ::'+results[1].event_status);
    }
		
		if(isSuccess && isValid){
				return res.status(200).json("Successfully committed the change to the ledger by the peer");

		} else {
				return res.status(500).json("Transaction failed to be committed to the ledger due to :: " + results[1].event_status);
		}

	}).catch((err) => {
		console.error('Failed to invoke successfully :: ' + err);
	});
});

app.get('/transaction/product/:id', (req,res) => {
	var userID = req.params.id;

	fabric_client.getUserContext(userID, true).then((user_from_store) => {
     if(user_from_store && user_from_store.isEnrolled()){
       console.log("Successfully loaded user from persistence");
       member_user = user_from_store;
     } else {
       console.log("failed to get user");
       return res.status(400).json("Failed to get user");
     }
		const request = {
			chaincodeId: ca_config.chaincodeid,
			fcn: 'getProductList',
			args: ['']
		};


     return channel.queryByChaincode(request);
   }).then((query_responses) => {
        console.log("Query has completed, checking results");
        // query_responses could have more than one  results if there multiple peers were used as targets
        if (query_responses && query_responses.length == 1) {
                if (query_responses[0] instanceof Error) {
			return res.status(500).json("error from query = ", query_responses[0]);
               } else {
			return res.status(200).json(query_responses[0].toString());
                }
        } else {
			return res.status(500).json("No payloads were returned from query");
        }
   }).catch((err) => {
			return res.status(500).json('Failed to query successfully :: ' + err);
   });

}); 

app.listen(3001, () => {

  let ordererserverCert = fs.readFileSync(path.join(__dirname, '../../crypto-config/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/tls/ca.crt'));
  let peerserverCert = fs.readFileSync(path.join(__dirname, '../../crypto-config/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt'));

  channel = fabric_client.newChannel(ca_config.channel_name);
  peer = fabric_client.newPeer(ca_config.peer_url,{
      'pem': Buffer.from(peerserverCert).toString(),
      'ssl-target-name-override': "peer0.store1.mymarket.com",
    });
  channel.addPeer(peer);
  order = fabric_client.newOrderer(ca_config.orderer_url,{
      'pem': Buffer.from(ordererserverCert).toString(),
      'ssl-target-name-override': "orderer1.mymarket.com",
    });
  channel.addOrderer(order);

Fabric_Client.newDefaultKeyValueStore({ path: store_path
  }).then((state_store) => {
    fabric_client.setStateStore(state_store);
    var crypto_suite = Fabric_Client.newCryptoSuite();
    var crypto_store = Fabric_Client.newCryptoKeyStore({path: store_path});
    crypto_suite.setCryptoKeyStore(crypto_store);
    fabric_client.setCryptoSuite(crypto_suite);
    var tlsOptions = {
        trustedRoots: [],
        verify: false
    };
    // be sure to change the http to https when the CA is running TLS enabled
    fabric_ca_client =  new Fabric_CA_Client(ca_config.ca_connection_url, null , '', crypto_suite);

   return fabric_client.getUserContext(ca_config.ca_admin_id,true);
}).then((user_from_store) => {admin_user = user_from_store});

  console.log('Example app listening on port 3001!');
});
