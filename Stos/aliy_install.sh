#!/bin/bash
for i in {1..10}
do
sdsHome=/root/rsnode/rsnode${i}
mkdir $sdsHome
cp ~/ppd $sdsHome/
apt -y install expect > /dev/null

cat >/root/rsnode/rsnode${i}/installSds.sh << EOF
#!/usr/bin/expect
spawn /root/rsnode/rsnode${i}/ppd config -w -p
expect "password"
send "Night123\n"
expect "again"
send "Night123\n"
expect "nickname"
send "melody\n"
expect "password"
send "Night123\n"
expect "again"
send "Night123\n"
expect "input"
send "betray flip change pencil language camera thunder reason mimic crouch seek addict grant lonely slow toward grass menu infant total faint reunion clarify jewel\n"
expect "input"
send "\n"
expect "save"
send "Y\n"
expect off
EOF
sleep 5s
chmod +x $sdsHome/installSds.sh
chmod +x $sdsHome/ppd
cd $sdsHome
nohup $sdsHome/installSds.sh 2>&1  >> install.log &
sleep 5s
double=$(( 300 *  $i ))
gongwnag=`curl -s cip.cc  |grep "IP" |awk '{print $3}'`
Netw=`expr 18081 + ${double}`
sed -i  's/127.0.0.1:8888/13.58.35.167:8888/g' $sdsHome/configs/config.yaml
sed -i "/NetworkAddress/ s/127.0.0.1/$gongwnag/g" $sdsHome/configs/config.yaml
sed -i "/Port/ s/18081/${Netw}/g" $sdsHome/configs/config.yaml
sed -i "s@StratosChainUrl: http://127.0.0.1:1317@StratosChainUrl: https://rest-tropos.thestratos.org:443@g" $sdsHome/configs/config.yaml
sed -i s/tropos-1/tropos-3/g $sdsHome/configs/config.yaml
sed -i 's/downloadpathminlen: 88/downloadpathminlen: 0/g' $sdsHome/configs/config.yaml

done