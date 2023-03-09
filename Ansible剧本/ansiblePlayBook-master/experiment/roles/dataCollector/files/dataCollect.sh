#!/bin/bash
#This script is for running time data collecting

#rm -rf ~/log/dataCollect.*

while true 
do

##############

curtime=`date +'%Y-%m-%d %H:%M:%S'`
echo $curtime," ----- start to collecting data -----"
echo "staging size: `du -m ~/.filecoin_sectors/staging --exclude=blobs | awk '{print int($1)}'` MB"
echo "sealed size: `du -m ~/.filecoin_sectors/sealed | awk '{print int($1)}'` MB"
echo "power is: `~/bin/go-filecoin config mining | jq ".minerAddress" | xargs ~/bin/go-filecoin miner power`"

echo "node block height: `~/bin/go-filecoin chain  head --enc=json|jq -r '.[0]|."/"' |  xargs -L1 ~/bin/go-filecoin show block --enc=json | jq -r '.height'`"
echo "current IPFS block height: `curl -sSl https://prod-devnet.filecoin-stats-infra.kyokan.io/sync | jq -r '.mining.lastBlockHeight'`"

#重启次数计算依赖统计守护进程的log文件
echo "total restart times: `ls -l |grep "filecoin.filGuard"|wc -l`"

##############

sleep 10m
done
exit 0
