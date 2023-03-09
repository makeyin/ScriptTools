#!/bin/bash
tapUrl=http://43.254.11.178:9292
code=`ifconfig |grep inet|grep -v 127.0.0.1|grep -v 192.168|grep -v inet6|awk '{print $2}' | awk -F"/" '{print $1}' |awk -F "." '{print  $4}'`
url=http://yuyin.market.alicloudapi.com/yzx/voiceSend\?mobile\=13402039095\&param\=code%3A0$code
while true
do
walletID=`~/bin/lotus wallet new`
echo -e "\033[32;49;1m [开始时间] \033[39;49;0m" `date "+%Y-%m-%d %H:%M:%S"`
mkdir -p  ~/1475/$walletID/tmp
echo $walletID > ~/1475/$walletID/wallet
curl -i -X POST -D ~/1475/$walletID/tmp/1.txt -d "address=$walletID&sectorSize=34359738368" $tapUrl/mkminer
cat ~/1475/$walletID/tmp/1.txt |grep Location |awk -F "f=" '{print $2}'|awk -F "&m" '{print $1}' > ~/1475/$walletID/tmp/2.txt
curl $tapUrl/msgwaitaddr?cid=`cat ~/1475/$walletID/tmp/2.txt` >~/1475/$walletID/tmp/3.txt
cat ~/1475/$walletID/tmp/3.txt |awk -F ":" '{print $2}'|awk -F "}" '{print $1}' >~/1475/$walletID/tmp/4.txt
cat ~/1475/$walletID/tmp/4.txt |sed 's/ //g'|sed  's/"//g' >~/1475/$walletID/tmp/5.txt
miner=`cat ~/1475/$walletID/tmp/5.txt`
echo $miner > ~/1475/$walletID/miner
mv  ~/1475/$walletID ~/1475/$miner
if [ -d "/home/devnet/1475/t01475" ]; then
        echo -e "\033[32;49;1m ---[1475已抢到]--- \033[39;49;0m"
        curl -XPOST -s -L -H "Content-Type:text/plain" -H "charset:utf-8" -H "Authorization:APPCODE 1d5c15b9fe784a1a84c0cf3aaeac5231" $url
else
        echo -e "\033[32;49;1m [没有刷到1475，继续刷单,刷到了$miner] \033[39;49;0m" `date "+%Y-%m-%d %H:%M:%S"`
fi
   echo -e "\033[32;49;1m [结束时间] \033[39;49;0m" `date "+%Y-%m-%d %H:%M:%S"`
sleep 5s
echo "-----------------------------------------------------------------------------------------------------------------"
done