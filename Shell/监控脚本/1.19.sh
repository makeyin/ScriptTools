


cat >/script/get_mbi.sh<<'EOF'

winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "get mbi info timeout for" |wc -l
EOF

cat >/script/failed_getting.sh<<'EOF'

winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed getting beacon entry" |wc -l
EOF



cat >/script/received.sh<<'EOF'

winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "received wtask timeout" |wc -l
EOF


cat >>/etc/zabbix/zabbix_agentd.d/wnlog.conf<<EOF
UserParameter=getmbi,sudo sh /script/get_mbi.sh
UserParameter=fgetting,sudo sh /script/failed_getting.sh
UserParameter=received,sudo sh /script/received.sh
EOF


chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent.service
