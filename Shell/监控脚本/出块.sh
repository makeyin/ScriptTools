umb1=`curl https://filfox.info/api/v1/address/f089551/blocks\?pageSize\=20\&page\=0 |awk -F ',' '{print $3}' |awk -F ':' '{print $2}'`
umb2=`curl https://filfox.info/api/v1/address/f089551/blocks\?pageSize\=20\&page\=0  |awk -F 'height' '{print $2,$3}' |awk -F',' '{print $9}' |awk -F ':' '{print $2}'`


时间：
ps -eo pid,lstart,etime,cmd | grep 'lotus dae[mon]' | awk '{print $7}'





#/bin/bash
cat >/script/meichukuai.sh<<'EOF'
curl https://filfox.info/api/v1/address/f079815/blocks\?pageSize\=20\&page\=0 |awk -F ',' '{print $3}' |awk -F ':' '{print $2}' > /script/qukuai.txt
EOF


cat >>/etc/zabbix/zabbix_agentd.d/meichukuai.conf<<EOF
UserParameter=meichukuai,sudo cat  /script/qukuai.txt
EOF


chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/meichukuai.conf
systemctl restart zabbix-agent.service

echo "0 */2 * * * sh /script/meichukuai.sh"  >> /var/spool/cron/crontabs/root