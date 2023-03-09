#!/bin/bash
while true
do
rsync -rvzuP  --delete /home/devnet/.lotus/datastore/  /tmp/ChainData_Backup/lotus
sleep 30m
done