#!/bin/bash 
sysUser=$1
minerId=$2
askId=$3
nickname=$4
powerFileName=$5
#kill -9 `cat ~/log/PID.POWER`
kill -9 `ps -u $sysUser -f|grep autoDeal250MB|grep -v grep|awk '{print $2}'`

rm -rf /home/$sysUser/clientLog/power.*
rm -rf /home/$sysUser/clientLog/PID.*.POWER
mkdir -p /home/$sysUser/clientLog

echo "Check that if $powerFileName alreay exists "
if [ ! -f "/data/powerData/$powerFileName" ];
then
    echo "No $powerFileName file, start to create under ~/clientData  ..."
    dd if=/dev/zero of=/home/$sysUser/clientData/$powerFileName bs=1M count=245  #creat 250MB file
    powerFile=/home/$sysUser/clientData/$powerFileName
    echo "Create file $powerFile  done!"
else
    powerFile=/data/powerData/$powerFileName
    echo "$powerFile file alreay exists"
fi
# output the hash-value 
echo "Begin to get the hash of $powerFile"
rm -f /home/$sysUser/clientLog/record256.txt
if [ ! -f "/home/$sysUser/clientLog/record256.txt" ];
then
    echo "Begin to do client import"
    ~/bin/go-filecoin client import $powerFile > /home/$sysUser/clientLog/record256.txt
    file_hash=`cat /home/$sysUser/clientLog/record256.txt`
    echo "File $powerFileName Hash is:${file_hash}"
else
    file_hash=`cat /home/$sysUser/clientLog/record256.txt`
    echo "File $powerFileName Hash is:${file_hash}"
fi

minerIdArray=(${minerId//,/ })
for miner_id in ${minerIdArray[@]}
do
    setsid ~/bin/autoDeal250MB.sh $sysUser $miner_id $askId $file_hash > ~/clientLog/power.1.$miner_id.`date +"%m%d%H%M"`.out 2>&1  &
    echo $! > ~/clientLog/PID.1.$miner_id.POWER
    
    #setsid ~/bin/autoDeal250MB.sh $sysUser $miner_id $askId $file_hash > ~/clientLog/power.2.$miner_id.`date +"%m%d%H%M"`.out 2>&1  &
    #echo $! > ~/clientLog/PID.2.$miner_id.POWER

    #setsid ~/bin/autoDeal250MB.sh $sysUser $miner_id $askId $file_hash > ~/clientLog/power.3.$miner_id.`date +"%m%d%H%M"`.out 2>&1  &
    #echo $! > ~/clientLog/PID.3.$miner_id.POWER
done
