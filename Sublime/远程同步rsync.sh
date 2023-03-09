#!/bin/bash

#定义变量

Host=$(hostname)
IP=$(ifconfig eth1|awk 'NR==2{print $2}')
Date=$(date +%F)
BackupDir=/backup
Dest=${BackupDir}/${Host}_${IP}_${Date}

#
mkdir -p $Dest

echo "create is ok >>>ok"

#
#cp -p /etc/fstab /etc/hosts /var/spool/cron/root $Dest
#cp -p /var/log/messages /var/log/secure /var/log/cron $Dest
#cp -p /etc/rsyncd.conf $Dest

# 打包需要备份的文件
tar -zcPf $Dest/log.tar.gz /etc/fstab /etc/hosts /var/spool/cron/root $Dest
tar -zcPf $Dest/sysconf.tar.gz /var/log/messages /var/log/secure /var/log/cron $Dest
tar -zcPf $Dest/svrconf.tar.gz /etc/rsyncd.conf $Dest


# md5 校验
md5sum $Dest/* > $Dest/backup_check_$Date

#push 免密推送
export RSYNC_PASSWORD=123456

rsync -avz $Dest rsync_backup@172.16.1.41::backup/ --password-file=/etc/rsync.password

#保留七天删除

find $BackupDir -type d -mtime +7 |xargs rm -rf

 

服务器校验
（2）
md5sum -c /backup/*_$(date +%F)/backup_check* >/backup/*_$(date +%F)/result.txt