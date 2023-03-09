#!/bin/bash
lotus=`ps -ef |grep '[l]otus daemon' |wc -l`
lotuswindow=`ps -ef |grep '[l]otus-window'  |wc -l`
lotuswinning=`ps -ef |grep '[l]otus-winning'  |wc -l`
lotusminer=`ps -ef |grep '[l]otus-power'  |wc -l`

if [ "$lotus" -eq "1" ];then
cat >/script/cannot.sh<<'EOF'
lotushome=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $2}'`
lotususer=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $3}'`
logfile=`ls -lt /$lotushome/$lotususer/log | awk '{print $NF}' | grep lotus | head -1`
tail -20 /$lotushome/$lotususer/log/$logfile |grep "cannot allocate memory" | wc -l
EOF

cat >/script/ApplyBlock.sh<<EOF
lotushome=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $2}'`
lotususer=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $3}'`
logfile=`ls -lt /$lotushome/$lotususer/log | awk '{print $NF}' | grep lotus | head -1`
grep "ApplyBlock" /$lotushome/$lotususer/log/$logfile |  tail -1000 | awk -F'["]' '{print $22}' | awk -F's' '{x+=$1} END{print x/NR}'
EOF

cat >>/etc/zabbix/zabbix_agentd.d/ApplyBlock.conf<<EOF
UserParameter=ApplyBlock,sudo sh /script/ApplyBlock.sh
EOF

elif [ "$lotuswindow" -eq "1" ];then
cat >/script/cannot.sh<<'EOF'
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail /$windowhome/$windowuser/log/$wdlogfile |grep "cannot allocate memory" |wc -l
EOF

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

elif [ "$lotuswinning" -eq "1" ];then
cat >/script/cannot.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "cannot allocate memory" |wc -l
EOF

cat >/script/rpcwn.sh<<'EOF'

winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "rpc" |wc -l
EOF

cat >>/etc/zabbix/zabbix_agentd.d/rpcwn.conf<<EOF
UserParameter=rpcwn,sudo sh /script/rpcwn.sh
EOF

cat >/script/send_win_failed.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "send win failed" |wc -l
EOF

cat >>/etc/zabbix/zabbix_agentd.d/sendfailed.conf<<EOF
UserParameter=sendfailed,sudo sh /script/send_win_failed.sh
EOF

else
cat >/script/cannot.sh<<'EOF'
powerhome=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $2}'`
poweruser=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $3}'`
powerlogfile=`ls -lt /$powerhome/$poweruser/log | awk '{print $NF}' | grep lotus | head -1`
tail -20 /$powerhome/$poweruser/log/$powerlogfile |grep "cannot allocate memory" | wc -l
EOF

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

fi
##################################################################################内存##################################
cat >/script/memmax.sh<<'EOF'
#!/bin/bash
mem_used=`free -m | grep '^Mem:' | awk '{print $3}'`
mem_total=`free -m | grep '^Mem:' | awk '{print $2}'`
expr 100 \* $mem_used / $mem_total
EOF

cat >>/etc/zabbix/zabbix_agentd.d/cannot.conf<<EOF
UserParameter=cannot,sudo sh /script/cannot.sh
UserParameter=memmax,sudo sh /script/memmax.sh
EOF

chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent.service
