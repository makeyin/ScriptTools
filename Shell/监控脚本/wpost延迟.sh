#!/bin/bash
bin_path=/home/devnet/bin/lotus
lotus_api='http://10.10.8.7:1234/rpc/v0'
if [ -n "$1" ];then
        MINER_ID=$1
else
        echo "Missing parameters, can be \$1=$1"
        exit 1
fi

proving_info=$(sudo runuser -l devnet -c  "$bin_path proving info $MINER_ID")

Sectors=$(echo "$proving_info" |awk '/Deadline Sectors/{print $NF}')
DeadlineIndex=$(echo "$proving_info" |awk '/Deadline Index/{print $NF}')
CurrentEpoch=$(echo "$proving_info" |awk '/Current Epoch/{print $NF}')
DeadlineOpen=$(echo "$proving_info" |awk '/Deadline Open/{print $3}')

# 判断index 不需要做wpost
if [ $Sectors -eq 0 ];then
        echo -1
        exit 2
fi

unProvenPartitions=$(sudo runuser -l devnet -c  "$bin_path prove deadlines $MINER_ID" |awk -v DeadlineIndex="$DeadlineIndex" '{if($1 == DeadlineIndex){print ($2 - $6)}}')

if [ $unProvenPartitions -eq 0 ]; then
        echo $unProvenPartitions
else
        diffEpoch=$(echo "$CurrentEpoch - $DeadlineOpen" |bc)
        Threshold=$(sqlite3 -separator " " /script/wallet_alert_manage/db.sqlite3 'select threshold3 from wallet_alert_manage_miner_info where miner_id='\'$MINER_ID\')
        # wpost 超时
        if [ $diffEpoch -ge $Threshold ];then
                echo -3
                exit 3
        else
                # wpost 未超时
                echo -2
                exit 4
        fi
fi