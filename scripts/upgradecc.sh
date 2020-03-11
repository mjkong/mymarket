#!/bin/sh

CC_VERSION=$1
DELAY=10
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem
LANGUAGE="golang"
#CC_SRC_PATH=github.com/chaincode/chaincode_example02/go
CC_SRC_PATH=github.com/chaincode/mymarket/go
COUNTER=1

. ./scripts/utils.sh

installChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        VERSION=${CC_VERSION}
        set -x
        peer chaincode install -n marketcc -v ${VERSION} -l ${LANGUAGE} -p ${CC_SRC_PATH} &> log.txt
        res=$?
        set +x
        cat log.txt
        verifyResult $res "Chaincode installation on peer${PEER}.store${ORG} has Failed"
        echo "===================== Chaincode is installed on peer${PEER}.store${ORG} ===================== "
	sleep $DELAY
        echo
}

instantiateChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        VERSION=${CC_VERSION}

        # while 'peer chaincode' command can get the orderer endpoint from the peer (if join was successful),
        # lets supply it directly as we know it using the "-o" option
        if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
                peer chaincode upgrade -o orderer1.mymarket.com:7050 -C $CHANNEL_NAME -n marketcc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":[]}' -P "AND ('Store1MSP.peer','Store2MSP.peer')" &> log.txt
                res=$?
                set +x
        else
                set -x
                peer chaincode upgrade -o orderer1.mymarket.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n marketcc -l ${LANGUAGE} -v ${VERSION} -c '{"Args":[]}' -P "AND ('Store1MSP.peer','Store2MSP.peer')" &> log.txt
                res=$?
                set +x
        fi
        cat log.txt
        verifyResult $res "Chaincode instantiation on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' failed"
        echo "===================== Chaincode Instantiation on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' is successful ===================== "
	sleep $DELAY
        echo
}

installChaincode 0 1
installChaincode 1 1
installChaincode 0 2
installChaincode 1 2
instantiateChaincode 0 1