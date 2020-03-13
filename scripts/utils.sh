#!/bin/sh


verifyResult () {
        if [ $1 -ne 0 ] ; then
                echo "!!!!!!!!!!!!!!! "$2" !!!!!!!!!!!!!!!!"
    echo "========= ERROR !!! FAILED to execute End-2-End Scenario ==========="
                echo
                exit 1
        fi
}

# Set OrdererOrg.Admin globals
setOrdererGlobals() {
        CORE_PEER_LOCALMSPID="HeadquaterMSP"
        CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem
        CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/users/Admin@mymarket.com/msp
}

setGlobals () {
        PEER=$1
        ORG=$2
        if [ $ORG -eq 1 ] ; then
                CORE_PEER_LOCALMSPID="Store1MSP"
                CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/users/Admin@store1.mymarket.com/msp
                if [ $PEER -eq 0 ]; then
                        CORE_PEER_ADDRESS=peer0.store1.mymarket.com:7051
                else
                        CORE_PEER_ADDRESS=peer1.store1.mymarket.com:8051
                fi
        elif [ $ORG -eq 2 ] ; then
                CORE_PEER_LOCALMSPID="Store2MSP"
                CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/peers/peer0.store2.mymarket.com/tls/ca.crt
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/users/Admin@store2.mymarket.com/msp
                if [ $PEER -eq 0 ]; then
                        CORE_PEER_ADDRESS=peer0.store2.mymarket.com:9051
                else
                        CORE_PEER_ADDRESS=peer1.store2.mymarket.com:10051
                fi

        elif [ $ORG -eq 3 ] ; then
                CORE_PEER_LOCALMSPID="Store3MSP"
                CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store3.mymarket.com/peers/peer0.store3.mymarket.com/tls/ca.crt
                CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store3.mymarket.com/users/Admin@store3.mymarket.com/msp
                if [ $PEER -eq 0 ]; then
                        CORE_PEER_ADDRESS=peer0.store3.mymarket.com:7051
                else
                        CORE_PEER_ADDRESS=peer1.store3.mymarket.com:7051
                fi
        else
                echo "================== ERROR !!! ORG Unknown =================="
        fi

        env |grep CORE
}

joinChannelWithRetry () {
  PEER=$1
  ORG=$2
  setGlobals $PEER $ORG

        set -x
  peer channel join -b $CHANNEL_NAME.block  &> log.txt
  res=$?
        set +x
  cat log.txt
  if [ $res -ne 0 -a $COUNTER -lt $MAX_RETRY ]; then
    COUNTER=` expr $COUNTER + 1`
    echo "peer${PEER}.store${ORG} failed to join the channel, Retry after $DELAY seconds"
    sleep $DELAY
    joinChannelWithRetry $PEER $ORG
  else
    COUNTER=1
  fi
  verifyResult $res "After $MAX_RETRY attempts, peer${PEER}.org${ORG} has failed to Join the Channel"
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
  PACKAGE_ID=`grep marketcc_$CC_VERSION log.txt | sed -n '/Package/{s/^Package ID: //; s/, Label:.*$//; p;}'`
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