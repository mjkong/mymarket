#!/bin/sh

CC_VERSION=$1
DELAY=10
TIMEOUT=60
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem
PEER0_STORE1_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt
PEER0_STORE2_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/peers/peer0.store2.mymarket.com/tls/ca.crt

LANGUAGE="golang"
#CC_SRC_PATH=github.com/chaincode/chaincode_example02/go
CC_SRC_PATH=github.com/chaincode/mymarket/go
CC_RUNTIME_LANGUAGE=$LANGUAGE
COUNTER=1
MAX_RETRY=20
PACKAGE_ID=""
NO_CHAINCODE="false"

. ./scripts/utils.sh

  rm -f marketcc.tar.gz

  packageChaincode $CC_VERSION 0 1
## Install chaincode on peer0.store1 and peer0.store2
	echo "Installing chaincode on store1..."
	installChaincode 0 1
  installChaincode 1 1
	echo "Install chaincode on store2..."
	installChaincode 0 2
	installChaincode 1 2

	## query whether the chaincode is installed
	queryInstalled 0 1

	## approve the definition for store1
	approveForMyOrg $CC_VERSION 0 1
	approveForMyOrg $CC_VERSION 0 2

  checkCommitReadiness $CC_VERSION 0 1 "\"Store1MSP\": true" "\"Store2MSP\": true"
	checkCommitReadiness $CC_VERSION 0 2 "\"Store1MSP\": true" "\"Store2MSP\": true"

	## now that we know for sure both orgs have approved, commit the definition
	commitChaincodeDefinition $CC_VERSION 0 1 0 2

	# invoke init
	chaincodeInvoke 1 0 1 0 2