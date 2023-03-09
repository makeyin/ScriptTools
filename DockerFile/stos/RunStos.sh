#!/bin/bash
nohup ./ImportKey.sh >> import.log 2>&1  &
sleep 5s
nohup ./ChangeConfig.sh >> config.log  2>&1  &
sleep 5s
nohup ./ppd start  >> start.log 2>&1  &
sleep 5s
nohup ./init.sh  >> init.log 2>&1  &
