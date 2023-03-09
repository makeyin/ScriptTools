#!/bin/bash
wallet=`chia wallet show |grep "Total Balance" |grep -v "Pending" |awk -F ':' '{print $2}' |awk -F '(' '{print $1}' |awk -F '.' '{print $1}' `

if [ "$wallet" -gt  "0" ];then
curl 'https://oapi.dingtalk.com/robot/send?access_token=009c504c0bbf3c9ae9dea28ee038f4a3b06076f59774b626903d9cfeeb3bdcdf' \
   -H 'Content-Type: application/json' \
   -d '{"msgtype": "text",
        "text": {
             "content": "当前chia余额为'1',可以提币了"
        }
      }'
fi


