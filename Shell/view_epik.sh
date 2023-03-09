#!/bin/bash
##  设置 alias ve="~/bin/view_epik.sh"
#set -x

function start(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop epik"
  kill -9 `ps -u $USER -f | grep "epik daemon" | grep -v grep | grep -v view_epik.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep "epik daemon" | grep -v grep | grep -v view_epik.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for epik dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 10
  done
  mkdir -p ~/log

  echo `date +'%Y-%m-%d %H:%M:%S'` "start epik daemon"
  #rm -f ~/.epik/repo.lock
  #rm -f ~/.epik/datastore/LOCK
  setParam
  setsid ~/bin/epik daemon > ~/log/epik.`date +"%Y%m%d%H%M"`.out 2>&1 &
  #unset BELLMAN_NO_GPU
  echo $! > ~/bin/PID.NODE

  sleep 2
  startTryNum=1
  ~/bin/epik net id
  while [ "$?" != "0" -a $startTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for epik daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/epik net id
  done
  #exit 0
}

function startMiner(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop epik-miner"
  kill -9 `ps -u $USER -f | grep epik-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep epik-miner | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for epik-miner dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  echo `date +'%Y-%m-%d %H:%M:%S'` "start epik-miner run"
  #rm -f ~/.lotusminer/repo.lock
  #rm -f ~/.lotusminer/datastore/LOCK

  setParam
  #export OPTION20=false
  setsid ~/bin/epik-miner run > ~/log/epik-miner.`date +"%Y%m%d%H%M"`.out 2>&1 &
 
  startTryNum=1
  ~/bin/epik-miner net id
  while [ "$?" != "0" -a $startTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for epik-miner daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 20
      ~/bin/epik-miner net id
  done
  #echo `date +'%Y-%m-%d %H:%M:%S'` "mpool setconfig"
  #~/bin/lotus mpool setconfig --proven 800 --pre 1000 --window 1000 --deal 1000 --other 1500
}



function stopall(){
  #echo `date +'%Y-%m-%d %H:%M:%S'` "stop filGuard"
  #kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop epik-miner"
  kill -9 `ps -u $USER -f | grep epik-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus"
  kill -9 `ps -u $USER -f | grep epik | grep -v grep | grep -v view_epik.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep epik | grep -v grep | grep -v view_epik.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for epik dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 3
  done
}

:<<!
function slaveGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-slave"
  kill -9 `ps -u $USER -f | grep "filGuard.sh slave" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh-slave"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh slave >> ~/log/filGuard.out 2>&1  &
    else
        echo -e "\033[31m没有filGuard文件\033[0m"
  fi
}


function stopSlaveGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-slave"
  kill -9 `ps -u $USER -f | grep "filGuard.sh slave" | grep -v grep | awk '{print $2}'` 2> /dev/null
}
!



function info(){
  if [ -n "`ps -u $USER -f | grep epik-miner | grep -v grep`" ]
    then
        ~/bin/epik-miner info
  fi
}

function id(){

  if [ -n "`ps -u $USER -f | grep "epik daemon"  | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus net listen ---"
        ~/bin/epik net listen
  fi

  if [ -n "`ps -u $USER -f | grep epik-miner | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-power net listen ---"
        ~/bin/epik-miner net listen
  fi

}

function pwd(){
  if [ -n "`ps -u $USER -f | grep epik-miner | grep -v grep`" ]
    then
        echo  "~/bin/epik-miner proving deadlines ---"
        ~/bin/epik-miner proving deadlines
        exit 0
  fi
}

function pinfo(){
  if [ -n "`ps -u $USER -f | grep epik-miner | grep -v grep`" ]
    then
        echo  "~/bin/epik-miner proving info ---"
        ~/bin/epik-miner proving info
        exit 0
  fi
}
:<<!
function stopGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null
}
!

case "$1" in
  start|startFull)
        start
        ;;
  miner|power)
        startMiner
        ;;
  restart)
        stopall
        start
        startMiner
        ;;
  stopall)
        stopall
        ;;
  log)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep "epik[.]" | head  -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any epik.*.log"
        fi
        ;;
  mlog|logm)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep epik-miner | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any epik-miner.*.log"
        fi
        ;;
  tailm)
        tail -f ~/log/`ls -lt ~/log | awk '{print $NF}' | grep epik-miner | head -1` | egrep "mined new block|mineoneSep|received w-tasks|loop"
        ;;
  info)
        info
        ;;
  id)
        id
        ;;
  check)
        ~/bin/epik-miner sectors list
        ;;
  pwd)
       pwd
       ;;
  pinfo)
       pinfo
       ;;
  *)
        echo "Usage: ~/view_epik.sh {start|miner|restart|check|log|logm|info|id|pwd|pinfo}" || true
        exit 1
esac
exit 0