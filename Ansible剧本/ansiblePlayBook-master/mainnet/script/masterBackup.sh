#!/bin/bash
#先在两台服务器上配置免密
#在目标服务器copy文件设置777权限
#crontab设置每小时执行一次
#55 */1 * * *  rsync -avzuP -e 'ssh -p 45823' --delete /home/devnet/bin devnet@192.168.3.31:/home/devnet/master_bk
#55 */1 * * *  rsync -avzuP -e 'ssh -p 45823' --delete /home/devnet/.lotus devnet@192.168.3.31:/home/devnet/master_bk
#55 */1 * * *  rsync -avzuP -e 'ssh -p 45823' --delete /home/devnet/.lotusminer devnet@192.168.3.31:/home/devnet/master_bk

rsync -avzuP --delete /home/devnet/bin gpo@192.168.100.41:/home/devnet/master_bak
rsync -avzuP --delete /home/devnet/.lotus gpo@192.168.100.41:/home/devnet/master_bak
rsync -avzuP --delete /home/devnet/.lotusminer gpo@192.168.100.41:/home/devnet/master_bak



#实时的配置下面，不用配置crontab，要下载inotifywait
#/usr/local/inotify/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w %f %e' -e modify,delete,create,attrib /tmp/test/ | while read file
#do
#rsync -avzuP --delete /tmp/test/ root@192.168.192.136:/tmp/test/
#echo "${file}" >>/var/log/rsyncd.log 2>&1
#done
#exit 0