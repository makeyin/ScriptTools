#!/bin/bash
pip3 install ntplib

cat>/script/time.py<<EOF
import time
import ntplib
import sys
import os


def main():
    try:
        ntp_client = ntplib.NTPClient()
        response = ntp_client.request('ntp.aliyun.com')
        ntp_timeStamp = response.tx_time
        ntp_date = time.strftime('%Y-%m-%d', time.localtime(ntp_timeStamp))
        ntp_time = time.strftime('%X', time.localtime(ntp_timeStamp))
    except:
        print('阿里云ntp服务器坏了，更换其他的NTP服务器试试')
        sys.exit()

    #获取本地服务器时间
    local_timeStamp = time.time()

    #获取阿里云和本机的时间差
    diff = abs(ntp_timeStamp - local_timeStamp)
    print(round(diff,3))

if __name__ == '__main__':
    main()
EOF


cat >>/etc/zabbix/zabbix_agentd.d/check_OStime.conf<<EOF 
UserParameter=checktime,sudo python3 /script/time.py
EOF

chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/check_OStime.conf
systemctl restart zabbix-agent.service