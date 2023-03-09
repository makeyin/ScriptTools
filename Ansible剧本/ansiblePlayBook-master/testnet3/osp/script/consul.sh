#!/bin/bash
###本机IP
app_ip=192.169.1.1
port1=21371
##注册地址
regUrl=http://117.173.15.160:8500/v1/agent/service/register
http=http://$ip:$port
regName=prometheus-node-my
`curl -X PUT -d '{"id":"'"$app_ip"'-'"$port1"'","name":"'"$regName"'","address":"'"$app_ip"'","port":'"$port1"',"tags": ["node-exporter"]}' $regUrl`