#!/bin/sh

CHANNEL_NAME=$1
DELAY=$2
TIMEOUT=$3
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

createChannel() {
        setGlobals 0 1

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer channel create -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx &> log.txt
                res=$?
                set +x
        else
                set -x
                peer channel create -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA &> log.txt
                res=$?
                set +x
        fi
        cat log.txt
        verifyResult $res "Channel creation failed"
        echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
}

joinChannel () {
	sleep $DELAY
        for org in 1 2; do
            for peer in 0 1; do
                joinChannelWithRetry $peer $org
                echo "===================== peer${peer}.store${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
                sleep $DELAY
                echo
            done
        done
}

updateAnchorPeers() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer channel update -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx &> log.txt
                res=$?
                set +x
  else
                set -x
                peer channel update -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA &>log.txt
                res=$?
                set +x
  fi
        cat log.txt
        verifyResult $res "Anchor peer update failed"
        echo "===================== Anchor peers for store \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
        sleep $DELAY
        echo
}

createChannel

joinChannel

updateAnchorPeers 0 1

updateAnchorPeers 0 2

if [ "${NO_CHAINCODE}" != "true" ]; then

	## at first we package the chaincode
	packageChaincode 1 0 1

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
	approveForMyOrg 1 0 1
	approveForMyOrg 1 0 2

	## check whether the chaincode definition is ready to be committed
    ## expect store1 to have approved and store2 not to
	# checkCommitReadiness 1 0 1 "\"Store1MSP\": true" "\"Store2MSP\": false"
	# checkCommitReadiness 1 0 2 "\"Store1MSP\": true" "\"Store2MSP\": false"

	## check whether the chaincode definition is ready to be committed
	## expect them both to have approved
	checkCommitReadiness 1 0 1 "\"Store1MSP\": true" "\"Store2MSP\": true"
	checkCommitReadiness 1 0 2 "\"Store1MSP\": true" "\"Store2MSP\": true"

	## now that we know for sure both orgs have approved, commit the definition
	commitChaincodeDefinition 1 0 1 0 2

	# invoke init
	chaincodeInvoke 1 0 1 0 2
fi
