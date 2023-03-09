#!/bin/bash
cat >/script/beacon_error.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed getting beacon entry" |wc -l
EOF

cat >/script/onesepfailed.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "mine one sep failed: scratching ticket failed: key not found" |wc -l
EOF


cat >/script/syncblockfailed.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed to submit newly mined block: sync to submitted block failed" |wc -l
EOF


cat >>/etc/zabbix/zabbix_agentd.d/sendfailed.conf<<EOF
UserParameter=zabbix.winning.beaconerror,sudo sh /script/beacon_error.sh
UserParameter=zabbix.winning.onesepfailed,sudo sh /script/onesepfailed.sh
UserParameter=zabbix.winning.syncblockfailed,sudo sh /script/syncblockfailed.sh
EOF


chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent.service
