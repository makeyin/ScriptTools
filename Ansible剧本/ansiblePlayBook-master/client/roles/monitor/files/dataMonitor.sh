#!/bin/bash -x
#This script is for running time data collecting

sUser=filecoin
sUser=$1

stagingSize=`du -m ~/.filecoin_sectors/staging --exclude=blobs | awk '{print int($1)}'`
sealedSize=0
if [ -d "/home/$sUser/.filecoin_sectors/sealed" ];then
sealedSize=`du -m ~/.filecoin_sectors/sealed | awk '{print int($1)}'`
fi

lastSealedSize=0
if [ -f "/home/$sUser/log/lastSealedSize.out" ];then
lastSealedSize=`cat ~/log/lastSealedSize.out`
fi

nodeBlockHeight=`~/bin/go-filecoin chain  head --enc=json|jq -r '.[0]|."/"' |  xargs -L1 ~/bin/go-filecoin show block --enc=json | jq -r '.height'`
IPFSBlockHeight=`curl -sSl https://prod-devnet.filecoin-stats-infra.kyokan.io/sync | jq -r '.mining.lastBlockHeight'`
miningAddress=`~/bin/go-filecoin config mining | jq ".minerAddress" | sed 's/\"//g'`
power=`~/bin/go-filecoin config mining | jq ".minerAddress" | xargs ~/bin/go-filecoin miner power | awk '{print $1}'`
walletBalance=`~/bin/go-filecoin address ls |xargs -L1 ~/bin/go-filecoin wallet balance`
echo $miningAddress,$power,$stagingSize,$sealedSize,$lastSealedSize,$nodeBlockHeight,$IPFSBlockHeight,$walletBalance