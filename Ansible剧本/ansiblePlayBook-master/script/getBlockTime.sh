#/bin/sh
#set -x

minerNo="t01050"
blockFile="blockcid.txt"
logFile="/home/devnet/log/lotus.12131043.out"

~/bin/lotus chain list --count=100 | grep t01050 | awk -F': t01050' '{print $1}' | awk -F'[ ,]' '{print $NF}' > $blockFile

cat $blockFile | while read cid
do
  echo "\n"
  echo -n "区块时间为:            "
  ~/bin/lotus chain list --count=110 | grep $cid
  echo  -n "log 日志收到区块时间: "
  grep $cid $logFile --text | head -1
done