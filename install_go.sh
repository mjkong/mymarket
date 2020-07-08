#!/bin/bash

wget https://golang.org/dl/go1.14.4.linux-amd64.tar.gz
sudo tar -xvf go1.14.4.linux-amd64.tar.gz -C /usr/local/

mkdir -p $HOME/gopath

echo "GOROOT=/usr/local/go" >> $HOME/.profile
echo "GOPATH=$HOME/gopath" >> $HOME/.profile
echo "PATH=$PATH:$GOROOT/bin:$GOPATH/bin" >> $HOME/.profile
