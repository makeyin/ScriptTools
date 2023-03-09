#!/bin/bash
echo '47.97.231.249 customer.skyipfs.com' >> /etc/hosts
echo '47.97.231.249 iZbp155hqqcfh7x2vvmenmZ'  >> /etc/hosts

ips=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | awk -F '/' '{print $1}' | head -n 1`
sed  -i "s/172/$ips/g" filebeat.yml
echo "确认你的IP是$ips  , 不对去filebeat.yml里面改"

read -p "输入你的矿工号: " minner
echo "矿工号 $minner"
sed  -i "s/f021536/$minner/g" filebeat.yml

cat>/etc/systemd/system/filebeat.service<<EOF
[Unit]
Description=filebeat
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=/opt/filebeat/filebeat -c /opt/filebeat/filebeat.yml
SyslogIdentifier=filebeat
Restart=always

[Install]
WantedBy=multi-user.target
EOF
systemctl daemon-reload
systemctl start filebeat