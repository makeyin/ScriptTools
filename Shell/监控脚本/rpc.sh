###########################################################################window##################################################

#!/bin/bash
sudo su -
cat >/script/rpc.sh<<'EOF'

#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
rpc=`tail  /$windowhome/$windowuser/log/$wdlogfile |grep  "rpc" |wc -l`
vrpc=`tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep   "%+vRPC client error" |wc -l`
websocket=`tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "window post sched: %+vhandler: websocket connection closed" | wc -l`
expr $rpc + $vrpc + $websocket
EOF


cat >>/etc/zabbix/zabbix_agentd.d/rpc.conf<<EOF
UserParameter=rpc,sudo sh /script/rpc.sh
EOF

chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/rpc.conf
systemctl restart zabbix-agent.service


###########################################################################winning##################################################
cat >/script/rpcwn.sh<<'EOF'

winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "rpc" |wc -l
EOF

cat >>/etc/zabbix/zabbix_agentd.d/rpcwn.conf<<EOF
UserParameter=rpcwn,sudo sh /script/rpcwn.sh
EOF


chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/rpcwn.conf
systemctl restart zabbix-agent.service


###########################################################################power##################################################
cat >/script/rpcpower.sh<<'EOF'
#!/bin/bash
powerhome=`ps -ef|grep 'lotus-power r[un]' |awk -F '/' '/run/{print $2}'`
poweruser=`ps -ef|grep 'lotus-power r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$powerhome/$poweruser/log | awk '{print $NF}' | grep lotus-power | head -1`
tail /$powerhome/$poweruser/log/$wnlogfile |grep "websocket connection closed" |wc -l
EOF


cat >>/etc/zabbix/zabbix_agentd.d/rpcpower.conf<<EOF
UserParameter=rpcpower,sudo sh /script/rpcpower.sh
EOF


chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/rpcpower.conf
systemctl restart zabbix-agent.service