#!/bin/bash
### Usage: sh run_client.sh devnet all /home/ansible/ansiblePlayBook/privateNet/main_private_hosts
user=$1
miner_hosts=$2
hostfile=$3
hostfile=`readlink -f $hostfile`
echo `date +'%Y-%m-%d %H:%M:%S'` " NOTICE: host file is $hostfile"

cd /home/ansible/ansiblePlayBook/client

rm -f ~/clientData/client_host
ansible-playbook /home/ansible/ansiblePlayBook/client/clientPB.yml -i $hostfile -e "minerUser=$user miner_hosts=$miner_hosts hostfile=$hostfile" -f 30

while true
do
    while [ ! -f "/home/ansible/clientData/client_host" ]
    do

        echo `date +'%Y-%m-%d %H:%M:%S'` " NOTICE: no client_host file, going to sleep 5 min"
        sleep 5m
        ansible-playbook /home/ansible/ansiblePlayBook/client/clientPB.yml -i $hostfile -e "minerUser=$user miner_hosts=$miner_hosts hostfile=$hostfile" -f 30
    done
    ansible-playbook /home/ansible/ansiblePlayBook/client/sendPowerPB.yml -i ~/clientData/client_host -e "minerUser=$user miner_hosts=$miner_hosts" -f 30
    echo `date +'%Y-%m-%d %H:%M:%S'` " NOTICE: going to sleep 30 min"
    sleep 30m
    rm -f ~/clientData/client_host
done
exit 0