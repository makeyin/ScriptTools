#!/bin/bash 
#this is a script for auto-proposing deal to target-ask
#prepare a about 250MB-sizes
minerId=$1
file_hash=$2
sysUser=$3
askId=$4
maxPowerNum=$5

if [[ ! -n "$sysUser" ]];then
    sysUser="devnet"
fi
if [[ ! -n "$askId" ]];then
    askId=0
fi
if [[ ! -n "$maxPowerNum" ]];then
    maxPowerNum=6000
fi

echo "Begin to send power, recipient: $minerId"

a=1
for ((i=1; i<=$maxPowerNum; i++))
do

    echo `date +'%Y-%m-%d %H:%M:%S'` "--------- Start to send propose-deal for $a times ---------"
    ~/bin/go-filecoin client propose-storage-deal --allow-duplicates ${minerId} ${file_hash} ${askId} 2880
    echo "------"
    echo $?
    echo "------"
    date +'%Y-%m-%d %H:%M:%S'
    echo "钱包余额：`~/bin/go-filecoin address ls |xargs -L1 ~/bin/go-filecoin wallet balance `"
    echo `date +'%Y-%m-%d %H:%M:%S'` "--------- end propose-deal for $a times --------- "
    let a++
    sleep 30

done
