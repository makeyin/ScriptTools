#!/bin/bash
###  批量给机器注册到普罗米修斯,只适用于千岛湖机房  $./consul host_tmp

host_file=$1
regName=$2

if [[ ! -n "$regName" ]];then
    regName="self_yw"
fi

echo "Begin to read host ip from $host_file"

for line in `cat $host_file| grep -v '#'`
do
    app_ip=$line
    port1=19403
    ##注册地址
    regUrl=http://192.168.1.14:9091/v1/agent/service/register
    http=http://$ip:$port
    `curl -X PUT -d '{"id":"'"$app_ip"'-'"$port1"'","name":"'"$regName"'","address":"'"$app_ip"'","port":'"$port1"',"tags": ["node-exporter"]}' $regUrl`
done