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

packageChaincode() {
  VERSION=$1
  PEER=$2
  ORG=$3
  setGlobals $PEER $ORG
  set -x
  peer lifecycle chaincode package marketcc.tar.gz --path ${CC_SRC_PATH} --lang ${CC_RUNTIME_LANGUAGE} --label marketcc_${VERSION} >&log.txt
  res=$?
  set +x
  cat log.txt
  verifyResult $res "Chaincode packaging on peer${PEER}.store${ORG} has failed"
  echo "===================== Chaincode is packaged on peer${PEER}.store${ORG} ===================== "
  echo
}

installChaincode () {
        PEER=$1
        ORG=$2
        setGlobals $PEER $ORG
        set -x
        peer lifecycle chaincode install marketcc.tar.gz >&log.txt
        res=$?
        set +x
        cat log.txt
        verifyResult $res "Chaincode installation on peer${PEER}.store${ORG} has Failed"
        echo "===================== Chaincode is installed on peer${PEER}.store${ORG} ===================== "
	sleep $DELAY
        echo
}

queryInstalled() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  set -x
  peer lifecycle chaincode queryinstalled >&log.txt
  res=$?
  set +x
  cat log.txt
  PACKAGE_ID=`sed -n '/Package/{s/^Package ID: //; s/, Label:.*$//; p;}' log.txt`
  verifyResult $res "Query installed on peer${PEER}.store${ORG} has failed"
  echo PackageID is ${PACKAGE_ID}
  echo "===================== Query installed successful on peer${PEER}.store${ORG} on channel ===================== "
  echo
}

approveForMyOrg() {
  VERSION=$1
  PEER=$2
  ORG=$3
  setGlobals $PEER $ORG

  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer lifecycle chaincode approveformyorg --channelID $CHANNEL_NAME --name marketcc --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION} --waitForEvent >&log.txt
    set +x
  else
    set -x
    peer lifecycle chaincode approveformyorg --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name marketcc --version ${VERSION} --init-required --package-id ${PACKAGE_ID} --sequence ${VERSION} --waitForEvent >&log.txt
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode definition approved on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition approved on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' ===================== "
  echo
}

commitChaincodeDefinition() {
  VERSION=$1
  shift
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer lifecycle chaincode commit -o orderer1.mymarket.com:7050 --channelID $CHANNEL_NAME --name marketcc $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --init-required >&log.txt
    res=$?
    set +x
  else
    set -x
    peer lifecycle chaincode commit -o orderer1.mymarket.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA --channelID $CHANNEL_NAME --name marketcc $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --init-required >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Chaincode definition commit failed on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' failed"
  echo "===================== Chaincode definition committed on channel '$CHANNEL_NAME' ===================== "
  echo
}

# checkCommitReadiness VERSION PEER ORG
checkCommitReadiness() {
  VERSION=$1
  PEER=$2
  ORG=$3
  shift 3
  setGlobals $PEER $ORG
  echo "===================== Checking the commit readiness of the chaincode definition on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while
    test "$(($(date +%s) - starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
    sleep $DELAY
    echo "Attempting to check the commit readiness of the chaincode definition on peer${PEER}.store${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer lifecycle chaincode checkcommitreadiness --channelID $CHANNEL_NAME --name marketcc $PEER_CONN_PARMS --version ${VERSION} --sequence ${VERSION} --output json --init-required >&log.txt
    res=$?
    set +x
    test $res -eq 0 || continue
    let rc=0
    for var in "$@"
    do
        grep "$var" log.txt &>/dev/null || let rc=1
    done
  done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Checking the commit readiness of the chaincode definition successful on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! Check commit readiness result on peer${PEER}.store${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
    echo
    exit 1
  fi
}

# queryCommitted VERSION PEER ORG
queryCommitted() {
  VERSION=$1
  PEER=$2
  ORG=$3
  setGlobals $PEER $ORG
  EXPECTED_RESULT="Version: ${VERSION}, Sequence: ${VERSION}, Endorsement Plugin: escc, Validation Plugin: vscc"
  echo "===================== Querying chaincode definition on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while
    test "$(($(date +%s) - starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
    sleep $DELAY
    echo "Attempting to Query committed status on peer${PEER}.store${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer lifecycle chaincode querycommitted --channelID $CHANNEL_NAME --name marketcc >&log.txt
    res=$?
    set +x
    test $res -eq 0 && VALUE=$(cat log.txt | grep -o '^Version: [0-9], Sequence: [0-9], Endorsement Plugin: escc, Validation Plugin: vscc')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query chaincode definition successful on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! Query chaincode definition result on peer${PEER}.store${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
    echo
    exit 1
  fi
}

chaincodeQuery() {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG
  EXPECTED_RESULT=$3
  echo "===================== Querying on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME'... ===================== "
  local rc=1
  local starttime=$(date +%s)

  # continue to poll
  # we either get a successful response, or reach TIMEOUT
  while
    test "$(($(date +%s) - starttime))" -lt "$TIMEOUT" -a $rc -ne 0
  do
    sleep $DELAY
    echo "Attempting to Query peer${PEER}.store${ORG} ...$(($(date +%s) - starttime)) secs"
    set -x
    peer chaincode query -C $CHANNEL_NAME -n marketcc -c '{"Args":["getProductList",""]}' >&log.txt
    res=$?
    set +x
    test $res -eq 0 && VALUE=$(cat log.txt | awk '/Query Result/ {print $NF}')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
    # removed the string "Query Result" from peer chaincode query command
    # result. as a result, have to support both options until the change
    # is merged.
    test $rc -ne 0 && VALUE=$(cat log.txt | egrep '^[0-9]+$')
    test "$VALUE" = "$EXPECTED_RESULT" && let rc=0
  done
  echo
  cat log.txt
  if test $rc -eq 0; then
    echo "===================== Query successful on peer${PEER}.store${ORG} on channel '$CHANNEL_NAME' ===================== "
  else
    echo "!!!!!!!!!!!!!!! Query result on peer${PEER}.store${ORG} is INVALID !!!!!!!!!!!!!!!!"
    echo "================== ERROR !!! FAILED to execute End-2-End Scenario =================="
    echo
    exit 1
  fi
}

parsePeerConnectionParameters() {
  # check for uneven number of peer and org parameters
  if [ $(($# % 2)) -ne 0 ]; then
    exit 1
  fi

  PEER_CONN_PARMS=""
  PEERS=""
  while [ "$#" -gt 0 ]; do
    setGlobals $1 $2
    PEER="peer$1.store$2"
    PEERS="$PEERS $PEER"
    PEER_CONN_PARMS="$PEER_CONN_PARMS --peerAddresses $CORE_PEER_ADDRESS"
    if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "true" ]; then
      TLSINFO=$(eval echo "--tlsRootCertFiles \$PEER$1_STORE$2_CA")
      PEER_CONN_PARMS="$PEER_CONN_PARMS $TLSINFO"
    fi
    # shift by two to get the next pair of peer/org parameters
    shift
    shift
  done
  # remove leading space for output
  PEERS="$(echo -e "$PEERS" | sed -e 's/^[[:space:]]*//')"
}

chaincodeInvoke() {
  IS_INIT=$1
  shift
  parsePeerConnectionParameters $@
  res=$?
  verifyResult $res "Invoke transaction failed on channel '$CHANNEL_NAME' due to uneven number of peer and org parameters "

  if [ "${IS_INIT}" -eq "1" ]; then
    CCARGS='{"Args":[""]}'
    INIT_ARG="--isInit"
  else
    CCARGS='{"Args":["registProduct","dummy","100","Store1"]}'
    INIT_ARG=""
  fi

  # while 'peer chaincode' command can get the orderer endpoint from the
  # peer (if join was successful), let's supply it directly as we know
  # it using the "-o" option
  if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
    set -x
    peer chaincode invoke -o orderer1.mymarket.com:7050 -C $CHANNEL_NAME -n marketcc $PEER_CONN_PARMS ${INIT_ARG} -c ${CCARGS} >&log.txt
    res=$?
    set +x
  else
    set -x
    peer chaincode invoke -o orderer1.mymarket.com:7050 --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA -C $CHANNEL_NAME -n marketcc $PEER_CONN_PARMS ${INIT_ARG} -c ${CCARGS} >&log.txt
    res=$?
    set +x
  fi
  cat log.txt
  verifyResult $res "Invoke execution on $PEERS failed "
  echo "===================== Invoke transaction successful on $PEERS on channel '$CHANNEL_NAME' ===================== "
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
