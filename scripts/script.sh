#!/bin/sh

CHANNEL_NAME=$1
DELAY=$2
TIMEOUT=$3
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem
LANGUAGE="golang"
#CC_SRC_PATH=github.com/chaincode/chaincode_example02/go
CC_SRC_PATH=github.com/chaincode/mymarket/go

. ./scripts/utils.sh

createChannel() {
        setGlobals 0 1

        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer channel create -o orderer.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx &> log.txt
                res=$?
                set +x
        else
                set -x
                peer channel create -o orderer.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA &> log.txt
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
                echo "===================== peer${peer}.org${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
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
                peer channel update -o orderer.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx &> log.txt
                res=$?
                set +x
  else
                set -x
                peer channel update -o orderer.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/${CORE_PEER_LOCALMSPID}anchors.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA &>log.txt
                res=$?
                set +x
  fi
        cat log.txt
        verifyResult $res "Anchor peer update failed"
        echo "===================== Anchor peers for org \"$CORE_PEER_LOCALMSPID\" on \"$CHANNEL_NAME\" is updated successfully ===================== "
        sleep $DELAY
        echo
}

installChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        VERSION=${3:-1.0}
        set -x
        peer chaincode install -n marketcc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} &> log.txt
        res=$?
        set +x
        cat log.txt
        verifyResult $res "Chaincode installation on peer${PEER}.org${ORG} has Failed"
        echo "===================== Chaincode is installed on peer${PEER}.org${ORG} ===================== "
	sleep $DELAY
        echo
}

instantiateChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        VERSION=${3:-1.0}

        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer chaincode instantiate -o orderer.mymarket.com:7050 -C $CHANNEL_NAME -n marketcc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":[]}' -P "AND ('Store1MSP.peer','Store2MSP.peer')" &> log.txt
                res=$?
                set +x
        else
                set -x
                peer chaincode instantiate -o orderer.mymarket.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n marketcc -l ${LANGUAGE} -v 1.0 -c '{"Args":[]}' -P "AND ('Store1MSP.peer','Store2MSP.peer')" &> log.txt
                res=$?
                set +x
        fi
        cat log.txt
        verifyResult $res "Chaincode instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' failed"
        echo "===================== Chaincode Instantiation on peer${PEER}.org${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	sleep $DELAY
        echo
}

createChannel

joinChannel

updateAnchorPeers 0 1

updateAnchorPeers 0 2

installChaincode 0 1

installChaincode 1 1

installChaincode 0 2

installChaincode 1 2

instantiateChaincode 0 1
