#!/bin/bash 
#this is a script for auto-proposing deal to target-ask
#prepare a about 250MB-sizes
sysUser=$1
minerId=$2  #target miner address id
askId=$3    #ask id number
file_hash=$4
echo "Begin to send power, recipient: $minerId"

a=1
for ((i=1; i<=10000; i++))
do

    curtime=`date +'%Y-%m-%d %H:%M:%S'`
    echo $curtime,"--------- Start to send propose-deal for $a times ---------"
    ~/bin/go-filecoin client propose-storage-deal --allow-duplicates ${minerId} ${file_hash} ${askId} 2880
    date +'%Y-%m-%d %H:%M:%S'
    echo "钱包余额：`~/bin/go-filecoin address ls |xargs -L1 ~/bin/go-filecoin wallet balance `"
    curtime=`date +'%Y-%m-%d %H:%M:%S'`
    echo $curtime,"--------- end propose-deal for $a times --------- "
    let a++
    sleep 10

done
