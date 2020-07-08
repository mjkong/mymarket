#### invoke ####
peer chaincode invoke -o orderer1.mymarket.com:7050 --tls true --cafile /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/mymarket.com/orderers/orderer1.mymarket.com/msp/tlscacerts/tlsca.mymarket.com-cert.pem -C $CHANNEL_NAME -n marketcc --peerAddresses peer0.store1.mymarket.com:7051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store1.mymarket.com/peers/peer0.store1.mymarket.com/tls/ca.crt --peerAddresses peer0.store2.mymarket.com:9051 --tlsRootCertFiles /opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/peerOrganizations/store2.mymarket.com/peers/peer0.store2.mymarket.com/tls/ca.crt -c '{"Args":["registProducts","PD100","400","store1"]}'

#### query ####
peer chaincode query -C $CHANNEL_NAME -n marketcc -c '{"Args":["getProductList",""]}'
