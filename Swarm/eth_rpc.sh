#!/bin/bash
apt update > /dev/null 2>/dev/null
apt install net-tools
apt-get install software-properties-common -y > /dev/null 2>/dev/null
add-apt-repository ppa:git-core/ppa -y > /dev/null 2>/dev/null
add-apt-repository -y ppa:ethereum/ethereum > /dev/null 2>/dev/null
apt update > /dev/null 2>/dev/null
apt-get install ethereum -y > /dev/null 2>/dev/null
nohup geth --cache=10240 --goerli --rpc --rpcaddr 0.0.0.0 --rpcport=8545 --rpcvhosts=* --rpcapi=eth,net,rpc --syncmode=fast > /root/eth_rpc.log 2>&1 &
IP=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | awk -F '/' '{print $1}' | head -n 1`
echo "eth_rpc 地址为： http://$IP:8545"