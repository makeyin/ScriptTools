#!/bin/bash
#######ps -ef | grep copyParam |grep -v grep  |awk '{print $2}' |xargs kill -9
pkill -9 rsync
###开几个线程
num=6
###文件名
tarName=v27-32G-osp.tar
tarPath=/var/tmp/filecoin-proof-parameters
### 目标机器文件路径
hostFile=hosts
cp hosts hosts_bak
while true
do
for host in `cat hosts`
do
  rsyncCount=`ps -ef | grep "rsync -WavPur" |grep -v grep |wc -l`
  echo $rsyncCount
  if [[ ("${rsyncCount}" -lt "$num") ]];then
          echo -e "\033[41;37m -------------------------[添加线程数]当前线程数:$rsyncCount,添加IP:$host------------------------- \033[0m"
          nohup rsync -WavPur -e 'ssh -p 45823' $tarName devnet@$host:$tarPath &
          sed -i '/'$host'/d' $hostFile
  else
          echo -e "\033[41;37m -------------------------[线程数满了],设置$num;当前线程数:$rsyncCount------------------------- \033[0m"
  fi
done
sleep 10s
rsyncCount=`ps -ef | grep "rsync -WavPur" |grep -v grep |wc -l`
echo -e "\033[41;37m -------------------------[巡检线程数]当前线程数:$rsyncCount------------------------- \033[0m"
done