#!/bin/bash

CURRENT_DIR=$PWD
NO_CHAINCODE="false"
export COMPOSE_PROJECT_NAME=mymarket
export IMG_VERSION=2.0.0
CHANNEL_NAME=mymarketchannel
DELAY=10
TIMEOUT=60

if [ "${NO_CHAINCODE}" != "true" ]; then
  echo Vendoring Go dependencies ...
  pushd ./chaincode/mymarket/go
  GO111MODULE=on go mod vendor
  popd
  echo Finished vendoring Go dependencies
fi

docker-compose up -d

sleep $DELAY
docker exec cli scripts/script.sh $CHANNEL_NAME $DELAY $TIMEOUT
