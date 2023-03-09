#!/bin/bash

#最新的slave log

if [ -z "$1" ]; then
    echo "MinerId is empty! You need specify a minerID"
    exit 1
fi

minerId=$1
#minerId="t01102"

logfile=`ls -lt ~/log | awk '{print $NF}' | grep slave-miner | head -1`
mid=`grep "mid " /home/$USER/log/$logfile | tail -1 | awk -F' ' '{print $6}'`
sid=`grep "mid " /home/$USER/log/$logfile | tail -1 | awk -F' ' '{print $8}'`
echo "sid "$sid
if [ -z "$mid" ]; then
    echo "Mid is empty!"
    exit 1
fi

sid=$(($sid+1))
echo "sid "$sid


#计算需要提前生成的软链的扇区
sectorFile="/home/$USER/sectorIds"
sealnum=300
sectorids=`/home/$USER/bin/lotus-storage-miner sectors idgen  --count $sealnum --mid $mid --sid $sid | tail -$sealnum > $sectorFile`

mkdir -p /tank2/.lotusslave_2/cache
mkdir -p /tank2/.lotusslave_2/sealed

cat $sectorFile  | while read ss
do
  w="s-"$minerId"-"$ss
  echo $w
  mkdir -p /tank2/.lotusslave_2/cache/$w

  #软链
  cd /home/devnet/.lotusslave/cache
  ln -s /tank2/.lotusslave_2/cache/$w .
  #软链
  cd /home/devnet/.lotusslave/sealed
  ln -s /tank2/.lotusslave_2/sealed/$w .
done