
const express = require('express');
const app = express();
bodyParser = require('body-parser');
app.use(bodyParser.json());
app.use(bodyParser.urlencoded({ extended: true }));

const path = require('path');
const { FileSystemWallet, Gateway } = require('fabric-network');

// A wallet stores a collection of identities for use
const wallet = new FileSystemWallet('./wallet');

var gateway = null;
var network = null;
var contract = null;

app.get('/', (req, res) => {
	console.log(userStore)
	res.send("Hello");
  
 });

app.post("/store1/api/manager/product", (req,res) => {
  const name= req.body.name|| '';
  const qty= req.body.qty|| '';
  const owner = req.body.owner|| '';

  async function call() {
    result = await contract.submitTransaction('registProducts', name, qty, owner);
    return result.toString()
  }
  call().then((result) => {
    console.log(result)
  })
    return res.status(200).json({"status":"OK"})
});

app.get('/store1/api/manager/product/:id', (req,res) => {
  var productID = req.params.id;

  async function call() {

    if(productID = "all"){
      result = await contract.submitTransaction('getProductList');
      return result.toString();
    }else{
      result = await contract.submitTransaction('getProduct', productID);
      return result.toString();
    }
  }
  call().then((result) =>{
    return res.status(200).json(JSON.parse(result))
  })
});

app.listen(3000, () => {

  async function connectFabric() {
  console.log('Store1 app listening on port 3000!');
  gateway = new Gateway();
    try {
        const userName = 'User1@store1.mymarket.com';
				let connectionProfile = path.resolve('./config/mymarketStore1Connection.json');
        //let connectionProfile = yaml.safeLoad(fs.readFileSync('../config/mymarketStore1Connection.json', 'utf8'));
				const userExist = await wallet.exists(userName);

				console.log(userExist);

        let connectionOptions = {
            identity: userName,
            wallet: wallet,
            discovery: { enabled: true, asLocalhost: true}
        };

        console.log('Connect to Fabric gateway.');
        await gateway.connect(connectionProfile, connectionOptions);

        console.log('Use network channel: mymarketchannel.');
        network = await gateway.getNetwork('mymarketchannel');
        contract = await network.getContract('marketcc'); 

      }catch (error) {
        console.log(`Error processing transaction. ${error}`);
        console.log(error.stack);
      } 
    }

    connectFabric().then(() => {
      console.log('Successfully connect to Fabric gateway.');
  }).catch((e) => {
      console.log('Exception occured.');
      console.log(e);
      console.log(e.stack);
      process.exit(-1);
  });
});
