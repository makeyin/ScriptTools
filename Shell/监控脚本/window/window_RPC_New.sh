cat >/script/rpc_DialArgs.sh<<'EOF'
#/bin/bash
#1. 日志: DialArgs
#解释：与fullnode的网络连接断开了,需要检查fullnode相应lotus运行情况
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "DialArgs" |wc -l
EOF

cat >/script/rpc_token_cannotbenil.sh<<'EOF'
#/bin/bash
#2. 日志：Full node token info cannot be nil
#解释：配置文件中fullnod info的配置有误，需要检查配置
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "Full node token info cannot be nil" |wc -l
EOF

cat >/script/rpc_error.sh<<'EOF'
#/bin/bash
#3. 日志：NewFullNodeRPC error
#解释：无法建立,rpc连接,需要重启fullnode
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "NewFullNodeRPC error" |wc -l
EOF

cat >/script/rpc_ChainNotify_error.sh<<'EOF'
#/bin/bash
#4. 日志：ChainNotify error
#解释：订阅fullnode的chain head变化失败,会自动重试
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "ChainNotify error" |wc -l
EOF

cat >/script/rpc_channel_closed.sh<<'EOF'
#/bin/bash
#5. 日志：window post scheduler notifs channel closed
#解释：从通知通道获取最新的chain head失败,会自动重试
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "window post scheduler notifs channel closed" |wc -l
EOF

cat >/script/rpc_broken_pipe.sh<<'EOF'
#/bin/bash
#6. 日志：sending ping message.*write: broken pipe
#解释：这个可以自动重试，不影响window进程；所以降低报警级别，一个小时出现超过40次报警
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -200 /$windowhome/$windowuser/log/$wdlogfile |grep "sending ping message.*write: broken pipe" |wc -l
EOF

cat >/script/window_compute.sh<<'EOF'
#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -200 /$windowhome/$windowuser/log/$wdlogfile |grep "compute Snark proofs err" |wc -l
EOF


cat >>/etc/zabbix/zabbix_agentd.d/rpc_DialArgs.conf<<EOF
UserParameter=rpc-DialArgs,sudo sh /script/rpc_DialArgs.sh
UserParameter=rpc-cannotbenil,sudo sh /script/rpc_token_cannotbenil.sh
UserParameter=rpc-error,sudo sh /script/rpc_error.sh
UserParameter=rpc-Chainerror,sudo sh /script/rpc_ChainNotify_error.sh
UserParameter=rpc-channel-closed,sudo sh /script/rpc_channel_closed.sh
UserParameter=rpc-broken-pipe,sudo sh /script/rpc_broken_pipe.sh
UserParameter=window-compute,sudo sh /script/window_compute.sh
EOF



chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent.service













