#!/bin/sh

export COMPOSE_PROJECT_NAME=mymarket
export IMG_VERSION=2.0.0

docker-compose down
docker rm $(docker ps -qa)
docker volume prune -f

docker rmi $(docker images | grep "mymarket.com-marketcc" | awk '{print $3}')

rm -rf chaincode/mymarket/go/vendor
