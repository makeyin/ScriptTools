#!/bin/bash
# Usage1: ~/bin/startSendPower.sh t2wvetifr2ulqg3qjzajndl6qp54tuqwthkycnuzi devnet 20 1
# Usage2: ~/bin/startSendPower.sh t2wvetifr2ulqg3qjzajndl6qp54tuqwthkycnuzi,t2wvetifr2ulqg3qjzajndl6qp54tuqwthkycnuzi devnet 20 1
minerId=$1
sysUser=$2
maxPowerNum=$3
procNum=$4

powerFileName=$5
askId=$6
nickname=$7

if [[ ! -n "$sysUser" ]];then
    sysUser="devnet"
fi
if [[ ! -n "$askId" ]];then
    askId=0
fi
if [[ ! -n "$nickname" ]];then
    nickname="joyce"
fi
if [[ ! -n "$powerFileName" ]];then
    powerFileName="power_256MB"
fi
if [[ ! -n "$procNum" ]];then
    procNum=1
fi
if [[ ! -n "$maxPowerNum" ]];then
    maxPowerNum=600
fi

#kill -9 `cat ~/log/PID.POWER`
#kill -9 `ps -u $sysUser -f|grep autoDeal250MB|grep -v grep|awk '{print $2}'`

#rm -rf /home/$sysUser/clientLog/power.*
rm -rf /home/$sysUser/clientLog/PID.*.POWER
mkdir -p /home/$sysUser/clientLog

echo `date +'%Y-%m-%d %H:%M:%S'` "Check that if $powerFileName alreay exists "
if [ ! -f "/data/powerData/$powerFileName" ];
then
    echo `date +'%Y-%m-%d %H:%M:%S'` "No $powerFileName file, start to create under ~/clientData  ..."
    dd if=/dev/zero of=/home/$sysUser/clientData/$powerFileName bs=1M count=245  #creat 250MB file
    powerFile=/home/$sysUser/clientData/$powerFileName
    echo `date +'%Y-%m-%d %H:%M:%S'` "Create file $powerFile  done!"
else
    powerFile=/data/powerData/$powerFileName
    echo `date +'%Y-%m-%d %H:%M:%S'` "$powerFile file alreay exists"
fi

# output the hash-value
echo `date +'%Y-%m-%d %H:%M:%S'` "Begin to get the hash of $powerFile"
rm -f /home/$sysUser/clientLog/record256.txt
if [ -s "/home/$sysUser/clientLog/record256.txt" ];
then
    file_hash=`cat /home/$sysUser/clientLog/record256.txt`
    echo `date +'%Y-%m-%d %H:%M:%S'` "File $powerFileName Hash is:${file_hash}"
else
    echo `date +'%Y-%m-%d %H:%M:%S'` "Begin to do client import"
    ~/bin/go-filecoin client import $powerFile > /home/$sysUser/clientLog/record256.txt
    file_hash=`cat /home/$sysUser/clientLog/record256.txt`
    echo `date +'%Y-%m-%d %H:%M:%S'` "go-filecoin client import file $powerFileName Hash is:${file_hash}"
fi

minerIdArray=(${minerId//,/ })
for miner_id in ${minerIdArray[@]}
do
    for i in `seq 1 $procNum`
    do
        setsid ~/bin/autoDeal250MB.sh $miner_id $file_hash $sysUser $askId $maxPowerNum > ~/clientLog/power.$i.$miner_id.`date +"%m%d%H%M"`.out 2>&1  &
        echo $! > ~/clientLog/PID.$i.$miner_id.POWER
    done
done
