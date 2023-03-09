#!/bin/bash
for i in {1..50}
do
cat > /root/stos/rsnode${i}/startSds.sh <<EOF
#!/usr/bin/expect
set timeout 120
spawn /root/stos/rsnode${i}/ppd terminal --home=/root/stos/rsnode${i}
expect ">"
send "\n"
send "rp\n"
sleep 10
send "\n"
expect ">"
send "activate 1000000000 10000 1000000\n"
sleep 45
send "exit\r"
expect eof
EOF
cat > /root/stos/rsnode${i}/restartSds.sh <<EOF
while true
do
#sdsHome=/root/stos/rsnode${i}
sdsPort=\`grep -w Port /root/stos/rsnode${i}/configs/config.yaml |awk -F\" '{print \$2}'\`
listenPort=\`ss -anpt |grep LISTEN |grep ppd | grep \${sdsPort}\`
if [ ! -n "\$listenPort" ];then
        ps -ef |grep start |grep ppd | grep -w rsnode$i |grep -v grep |awk '{print \$2}' |xargs kill -9
        cd $sdsHome
        nohup /root/stos/rsnode${i}/ppd start --home=/root/stos/rsnode${i}  >> /root/stos/rsnode${i}/sds.log 2>&1 &
        sleep 4
        nohup /root/stos/rsnode${i}/startSds.sh >> /root/stos/rsnode${i}/terminal.log  2>&1 &
fi
sleep 10m
done
EOF
chmod +x /root/stos/rsnode${i}/startSds.sh
chmod +x /root/stos/rsnode${i}/restartSds.sh
cd /root/stos/rsnode${i}
nohup sh /root/stos/rsnode${i}/restartSds.sh &
done