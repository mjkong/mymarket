
## create channel.tx
export CHANNEL_NAME=mjmallcc  && /home/badm/go/src/github.com/hyperledger/fabric/build/bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

## create anchorpeer artifacts
/home/badm/go/src/github.com/hyperledger/fabric/build/bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store1MSP

/home/badm/go/src/github.com/hyperledger/fabric/build/bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store2MSP



## peer0.store1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mjmall.com/users/Admin@store1.mjmall.com/msp
CORE_PEER_ADDRESS=peer0.store1.mjmall.com:7051
CORE_PEER_LOCALMSPID="Store1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mjmall.com/peers/peer0.store1.mjmall.com/tls/ca.crt

## peer1.store1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mjmall.com/users/Admin@store1.mjmall.com/msp
CORE_PEER_ADDRESS=peer1.store1.mjmall.com:7051
CORE_PEER_LOCALMSPID="Store1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mjmall.com/peers/peer1.store1.mjmall.com/tls/ca.crt

## peer0.store2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mjmall.com/users/Admin@store2.mjmall.com/msp
CORE_PEER_ADDRESS=peer0.store2.mjmall.com:7051
CORE_PEER_LOCALMSPID="Store2MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mjmall.com/peers/peer0.store2.mjmall.com/tls/ca.crt

## peer1.store2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mjmall.com/users/Admin@store2.mjmall.com/msp
CORE_PEER_ADDRESS=peer1.store2.mjmall.com:7051
CORE_PEER_LOCALMSPID="Store2MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mjmall.com/peers/peer1.store2.mjmall.com/tls/ca.crt



## create channel
export CHANNEL_NAME=mjmallcc
peer channel create -o orderer.mjmall.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mjmall.com/orderers/orderer.mjmall.com/msp/tlscacerts/tlsca.mjmall.com-cert.pem

## update anchor peers
peer channel update -o orderer.mjmall.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Store1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mjmall.com/orderers/orderer.mjmall.com/msp/tlscacerts/tlsca.mjmall.com-cert.pem


peer channel update -o orderer.mjmall.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Store2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mjmall.com/orderers/orderer.mjmall.com/msp/tlscacerts/tlsca.mjmall.com-cert.pem



## chaincode install
peer chaincode install -n mjmallcc -v 1.0 -p github.com/chaincode/mjmall

## chaincode instantiate
peer chaincode instantiate -o orderer.mjmall.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mjmall.com/orderers/orderer.mjmall.com/msp/tlscacerts/tlsca.mjmall.com-cert.pem -C $CHANNEL_NAME -n mjmallcc -v 1.0 -c '{"Args":["init",""]}' -P "OR ('Store1MSP.peer','Store2MSP.peer')"


peer chaincode query -C $CHANNEL_NAME -n mjmallcc -c '{"Args":["getProductList",""]}'

peer chaincode invoke -o orderer.mjmall.com:7050  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mjmall.com/orderers/orderer.mjmall.com/msp/tlscacerts/tlsca.mjmall.com-cert.pem  -C $CHANNEL_NAME -n mjmallcc -c '{"Args":["registProducts","mjcar","1","mj"]}'




peer chaincode upgrade -o orderer.mjmall.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mjmall.com/orderers/orderer.mjmall.com/msp/tlscacerts/tlsca.mjmall.com-cert.pem -C $CHANNEL_NAME -n mjmallcc -v 1.1 -c '{"Args":["init",""]}' -P "OR ('Store1MSP.peer','Store2MSP.peer')"
