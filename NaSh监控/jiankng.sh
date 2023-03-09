#!/bin/bash
minerName=`docker ps -a |grep iron |grep miner|grep Up | awk '{print $NF}'`
nodeDockerStatus=`docker ps -a |grep iron |grep node|grep Up | wc -l`
nodePortStatus=`ss -anpt |grep LISTEN |grep 9033 | wc -l`
minerTotalHash=0
ipAddress=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | awk -F '/' '{print $1}' | head -n 1`
if [ ! -n "$minerName" ];then
        minerStatus=1
else
        minerStatus=0
                for Name in `echo $minerName`
                do
                                minerHash=`docker logs --tail=1 $Name | awk '{print $3}'`
                                minerTotalHash=`echo "scale=3;$minerHash + $minerTotalHash" | bc`
                done
                echo "minerHash $minerTotalHash" | curl --data-binary @- http://115.231.82.193:9091/metrics/job/ironfish/instance/miner/Graffiti/s-pool/ip_address/${ipAddress}
                echo "minerStatus $minerStatus" | curl --data-binary @- http://115.231.82.193:9091/metrics/job/ironfish/instance/miner/Graffiti/s-pool/ip_address/${ipAddress}

fi
if [ $nodeDockerStatus -ne 0 ] && [ $nodePortStatus -ne 0 ];then
        nodeStatus=0
                TotalBalance=`docker run --rm --interactive --network host --volume /root/.ironfish:/root/.ironfish registry.cn-shanghai.aliyuncs.com/sunnyboykeven/iron:latest accounts:balance | grep -w "The balance is" | awk '{print $5}' | tr -d [","]`
                AvailableBalance=`docker run --rm --interactive --network host --volume /root/.ironfish:/root/.ironfish registry.cn-shanghai.aliyuncs.com/sunnyboykeven/iron:latest accounts:balance | grep -w "available" | awk '{print $6}' | tr -d [","]`
                echo "nodeStatus $nodeStatus" | curl --data-binary @- http://115.231.82.193:9091/metrics/job/ironfish/instance/node/Graffiti/s-pool/ip_address/${ipAddress}
                echo "TotalBalance  ${TotalBalance}" |curl --data-binary @- http://115.231.82.193:9091/metrics/job/ironfish/instance/node/Graffiti/s-pool/ip_address/${ipAddress}
                echo "AvailableBalance  ${AvailableBalance}" |curl --data-binary @- http://115.231.82.193:9091/metrics/job/ironfish/instance/node/Graffiti/s-pool/ip_address/${ipAddress}
else
        nodeStatus=1
fi


apt install sysstat -y
cpud=`mpstat |grep all|awk '{print $4}'`
MemTotal=`free -h |grep Mem |awk '{print $2}'`
MenUse=`free -h |grep Mem |awk '{print $3}'`