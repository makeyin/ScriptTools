#!/bin/bash
#./start_farmer P盘绝对路径 日志绝对路径

count=1

for SUBSPACE_WALLET in `cat ~/subwallet.txt`
do 
sdsHome=$1/farmer${count}
mkdir -p  $sdsHome
cp ~/farmer $sdsHome/

cat >$1/farmer${count}/startfarmer.sh << EOF
nohup ./farmer --base-path $1/farmer${count}/farm \
farm --reward-address ${SUBSPACE_WALLET}  --plot-size 100G \
--node-rpc-url ws://127.0.0.1:9944 > ~$2/farmer${count}.log 2>&1 &
EOF
count=$(($count+1))

done