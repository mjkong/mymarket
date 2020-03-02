
## create channel.tx
export CHANNEL_NAME=mymarketchannel  && /home/badm/go/src/github.com/hyperledger/fabric/build/bin/configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME

## create anchorpeer artifacts
/home/badm/go/src/github.com/hyperledger/fabric/build/bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store1MSP

/home/badm/go/src/github.com/hyperledger/fabric/build/bin/configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store2MSP



## peer0.store1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/users/Admin@store1.mymarket.com/msp
CORE_PEER_ADDRESS=peer0.store1.mymarket.com:7051
CORE_PEER_LOCALMSPID="Store1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt

## peer1.store1
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/users/Admin@store1.mymarket.com/msp
CORE_PEER_ADDRESS=peer1.store1.mymarket.com:8051
CORE_PEER_LOCALMSPID="Store1MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/peers/peer1.store1.mymarket.com/tls/ca.crt

## peer0.store2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/users/Admin@store2.mymarket.com/msp
CORE_PEER_ADDRESS=peer0.store2.mymarket.com:9051
CORE_PEER_LOCALMSPID="Store2MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/peers/peer0.store2.mymarket.com/tls/ca.crt

## peer1.store2
CORE_PEER_MSPCONFIGPATH=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/users/Admin@store2.mymarket.com/msp
CORE_PEER_ADDRESS=peer1.store2.mymarket.com:10051
CORE_PEER_LOCALMSPID="Store2MSP"
CORE_PEER_TLS_ROOTCERT_FILE=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/peers/peer1.store2.mymarket.com/tls/ca.crt



## create channel
export CHANNEL_NAME=mymarketchannel
peer channel create -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem

## update anchor peers
peer channel update -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Store1MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem


peer channel update -o orderer1.mymarket.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/Store2MSPanchors.tx --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem



## chaincode install
peer chaincode install -n marketcc -v 1.0 -p github.com/chaincode/mymarket/go

## chaincode instantiate
peer chaincode instantiate -o orderer1.mymarket.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem -C $CHANNEL_NAME -n mymarketcc -v 1.0 -c '{"Args":["init",""]}' -P "OR ('Store1MSP.peer','Store2MSP.peer')"


peer chaincode query -C $CHANNEL_NAME -n marketcc -c '{"Args":["getProductList",""]}'

peer chaincode invoke -o orderer1.mymarket.com:7050  --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem  -C $CHANNEL_NAME -n marketcc -c '{"Args":["registProducts","mjcar","1","mj"]}'

peer chaincode invoke -o orderer1.mymarket.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem -C $CHANNEL_NAME -n marketcc --peerAddresses peer0.store1.mymarket.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt --peerAddresses peer0.store2.mymarket.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/peers/peer0.store2.mymarket.com/tls/ca.crt -c '{"Args":["registProducts","mjcar","1","mj"]}'




peer chaincode upgrade -o orderer1.mymarket.com:7050 --tls --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem -C $CHANNEL_NAME -n marketcc -v 1.1 -c '{"Args":["init",""]}' -P "OR ('Store1MSP.peer','Store2MSP.peer')"
