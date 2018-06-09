## Hyperledger Fabric을 이용한 상품 거래 시스템 개발

> 개발환경은 우분투 16.04 기반으로 테스트하여 작성하였습니다.

### 사전 개발 환경 준비
* Docker
    * 17.06.2-ce 이상
* Docker-compose
    * 1.14.0 이상 버전
* Golang
    * 1.10.x 버전 이상
* Nodejs
    * 8.x 버전
* NPM
    * 5.6
* 우분투
    * g++ 설치
    <pre><code>apt install g++</code></pre>


### VM 네트워크 설정

#### Docker swarm 네트워크 설정

* VM1
VM1에서 다음의 명령을 실행

<pre><code>docker swarm init</pre></code>


<pre><code>docker swarm join-token manager</pre></code>
위의 명령을 실행하면 아래와 같은 메시지를 확인 할 수 있으며 VM2에서 명령을 실행합니다.
<pre><code>docker swarm join --token SWMTKN-1-3uhjzu2hfh9x3yhwzleh326wud22yaee65kqb88pczx4m0uwij-40ksc4c7pnmj9b3okxdmc9wqp 10.142.0.3:2377</pre></code>

다음의 명령을 통해서 도커 네트워크를 생성합니다.
<pre><code>docker network create --attachable --driver overlay my-net</code></pre>

* VM1 / VM2

각 VM에서 현재의 github repository를 clone 합니다.

<pre><code>git clone https://github.com/mjkong/mymarket</code></pre>

### Fabric 네트워크를 위한 아티팩트 생성

인증서 생성
<pre><code>cryptogen generate --config=./crypto-config.yaml</code></pre>

아티팩트 생성
<pre><code>
mkdir channel-artifacts
export FABRIC_CFG_PATH=$PWD
export CHANNEL_NAME=mymarketchannel
configtxgen -profile TwoOrgsOrdererGenesis -outputBlock ./channel-artifacts/genesis.block
configtxgen -profile TwoOrgsChannel -outputCreateChannelTx ./channel-artifacts/channel.tx -channelID $CHANNEL_NAME
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store1MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store1MSP
configtxgen -profile TwoOrgsChannel -outputAnchorPeersUpdate ./channel-artifacts/Store2MSPanchors.tx -channelID $CHANNEL_NAME -asOrg Store2MSP
</pre></code>
