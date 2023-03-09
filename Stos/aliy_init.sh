#!/bin/bash
for i in {1..10}
do
cat > /root/rsnode/rsnode${i}/startSds.sh <<EOF
#!/usr/bin/expect
set timeout 120
spawn /root/rsnode/rsnode${i}/ppd terminal --home=/root/rsnode/rsnode${i}
expect ">"
send "\n"
send "rp\n"
sleep 10
send "\n"
expect ">"
send "activate 1000000000 10000 1000000\n"
sleep 45
send "startmining\n"
sleep 10
send "exit\r"
expect eof
EOF
cat > /root/rsnode/rsnode${i}/restartSds.sh <<EOF
while true
do
#sdsHome=/root/rsnode${i}
sdsPort=\`grep -w Port /root/rsnode/rsnode${i}/configs/config.yaml |awk -F\" '{print \$2}'\`
listenPort=\`ss -anpt |grep LISTEN |grep ppd | grep \${sdsPort}\`
if [ ! -n "\$listenPort" ];then
        ps -ef |grep start |grep ppd | grep -w rsnode$i |grep -v grep |awk '{print \$2}' |xargs kill -9
        cd $sdsHome
        nohup /root/rsnode/rsnode${i}/ppd start --home=/root/rsnode/rsnode${i} 2>&1  >> /root/rsnode/rsnode${i}/sds.log &
        sleep 4
        nohup /root/rsnode/rsnode${i}/startSds.sh 2>&1 >> /root/rsnode/rsnode${i}/terminal.log &
fi
sleep 10m
done
EOF
chmod +x /root/rsnode/rsnode${i}/startSds.sh
chmod +x /root/rsnode/rsnode${i}/restartSds.sh
cd /root/rsnode/rsnode${i}
nohup sh /root/rsnode/rsnode${i}/restartSds.sh &
done