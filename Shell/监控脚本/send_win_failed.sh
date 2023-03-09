#!/bin/bash
cat >/script/send_win_failed.sh<<'EOF'

winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "send win failed" |wc -l
EOF


cat >>/etc/zabbix/zabbix_agentd.d/sendfailed.conf<<EOF
UserParameter=sendfailed,sudo sh /script/send_win_failed.sh
EOF


chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent.service
