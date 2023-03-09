cat >/script/rpc_DialArgs.sh<<'EOF'
#/bin/bash
#1. 日志: DialArgs
#解释：与fullnode的网络连接断开了,需要检查fullnode相应lotus运行情况
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "\[wdpost\] Submitting window post"|grep "failed: exit 7" |wc -l
EOF