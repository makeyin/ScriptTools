#!/bin/bash
total_size=`chia farm summary |grep "Total size of plots:" |awk '{print $5}'`
wallet=`chia wallet show |grep "Total Balance" |grep -v "Pending" |awk -F ':' '{print $2}' |awk -F '(' '{print $1}' |awk -F '.' '{print $1}' `




curl http://crust-monitor.1caifu.com/api/chia/receiveMiningPoolProfit -X POST -d '{"amount": '$total_size',"difficulty": '$wallet' }' --header "Content-Type: application/json"
