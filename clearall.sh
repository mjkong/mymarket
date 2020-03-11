#!/bin/sh

export COMPOSE_PROJECT_NAME=mymarket

docker-compose down
docker rm $(docker ps -qa)
docker volume prune -f

docker rmi $(docker images | grep "mymarket.com-marketcc" | awk '{print $3}')