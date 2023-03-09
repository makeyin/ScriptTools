#!/bin/bash
cat >/script/ApplyBlock.sh<<EOF
lotushome=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $2}'`
lotususer=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $3}'`
logfile=`ls -lt /$lotushome/$lotususer/log | awk '{print $NF}' | grep lotus | head -1`
grep "ApplyBlock" /$lotushome/$lotususer/log/$logfile |  tail -1000 | awk -F'["]' '{print $22}' | awk -F's' '{x+=$1} END{print x/NR}'
EOF


cat >>/etc/zabbix/zabbix_agentd.d/ApplyBlock.conf<<EOF
UserParameter=ApplyBlock,sudo sh /script/ApplyBlock.sh
EOF

chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/ApplyBlock.conf
systemctl restart zabbix-agent.service