#!/bin/bash
#判断是否有script目录
if [ ! -d /opt/PromeScript ];then
mkdir -p /opt/PromeScript
fi

#判断是否启动了node_exporter
panduan=`ps aux |grep node_exporter |grep -v grep  |wc -l`
if [ $panduan -eq 1 ];then
exit 1
else
##启动node_exporter
docker run -d -p 9100:9100  -v "/proc:/host/proc:ro"  -v "/sys:/host/sys:ro"  -v "/:/rootfs:ro" --net="host"  registry.cn-shanghai.aliyuncs.com/sunnyboykeven/prom:node-exporter

cat >>/opt/PromeScript/begin.sh<<'EOF'
IP=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | awk -F '/' '{print $1}' | head -n 1`
##metrics
curl -X DELETE http://115.231.82.193:9091/metrics/job/ironfish/instance/$IP
curl -s  127.0.0.1:9100/metrics |curl --data-binary @- http://115.231.82.193:9091/metrics/job/Subspace/instance/$IP
EOF

cat >>/var/spool/cron/crontabs/root<<'EOF'
*/2 * * * * sh /opt/PromeScript/begin.sh
EOF
fi
