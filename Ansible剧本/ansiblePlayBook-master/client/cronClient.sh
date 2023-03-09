#!/bin/bash
# Usage: sh crontabClient.sh filecoin cz

minerUser=$1
miner_hosts=$2



### start send power at every hour
ansible localhost -m cron -a "name=sendPower hour=0-23 job='cd /home/ansible/ansiblePlayBook/client && sh run_client.sh $minerUser $miner_hosts'"


### stop the cron job of sending power
ansible localhost -m cron -a "name=sendPower state=absent"