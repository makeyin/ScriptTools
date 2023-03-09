#!/bin/bash
##  设置 alias vl="~/bin/view_lotus.sh"
#set -x

function start(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus"
  kill -9 `ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps aux | grep lotus | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 10
  done
  mkdir -p ~/log

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus daemon"
  rm -f ~/.lotus/repo.lock
  rm -f ~/.lotus/datastore/LOCK
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=true
  export OPTION2=true
  export OPTION3=5
  export OPTION4=true
  export OPTION5=true
  export OPTION6=4
  export OPTION7=9800
  export OPTION8=false
  export OPTION9=1
  export OPTION10=10
  export OPTION11=false
  setsid ~/bin/lotus daemon > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
  echo $! > ~/bin/PID.NODE

  sleep 2
  startTryNum=1
  ~/bin/lotus net id
  while [ "$?" != "0" -a $startTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/bin/lotus net id
  done
  #exit 0
}

function startMiner(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-storage-miner"
  kill -9 `ps -u $USER -f | grep lotus-storage-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps aux | grep lotus-storage-m | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-storage-miner dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-storage-miner run"
  rm -f ~/.lotusstorage/repo.lock
  rm -f ~/.lotusstorage/datastore/LOCK
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=true
  export OPTION2=true
  export OPTION3=5
  export OPTION4=true
  export OPTION5=true
  export OPTION6=4
  export OPTION7=9800
  export OPTION8=false
  export OPTION9=1
  export OPTION10=10
  export OPTION11=false
  setsid ~/bin/lotus-storage-miner run --nosync > ~/log/storage-miner.`date +"%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  ~/bin/lotus-storage-miner net id
  while [ "$?" != "0" -a $startTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-storage-miner daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 20
      ~/bin/lotus-storage-miner net id
  done
}

function startSlave(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-slave-miner"
  kill -9 `ps -u $USER -f | grep lotus-slave-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps aux | grep lotus-slave-m | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-slave-miner dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  rm -f ~/.lotusslave/repo.lock
  rm -f ~/.lotusslave/datastore/LOCK
  sleep 5
  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-slave-miner run"
  
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=true
  export OPTION2=true
  export OPTION3=5
  export OPTION4=true
  export OPTION5=true
  export OPTION6=4
  export OPTION7=9800
  export OPTION8=false
  export OPTION9=1
  export OPTION10=10
  export OPTION11=false
  setsid ~/bin/lotus-slave-miner run > ~/log/slave-miner.`date +"%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  ~/bin/lotus-slave-miner net id
  while [ "$?" != "0" -a $startTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-slave-miner daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/bin/lotus-slave-miner net id
  done
}

function startPoster(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-poster"
  #kill `ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'` 2> /dev/null
  ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'|xargs kill -9  2> /dev/null

  stopTryNum=1
  while [ -n "`ps aux | grep lotus-poster | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-poster dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 10
  done
  
  rm -f ~/.lotusposter/repo.lock
  rm -f ~/.lotusposter/datastore/LOCK
  sleep 5
  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-poster run"
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=true
  export OPTION2=true
  export OPTION3=5
  export OPTION4=true
  export OPTION5=true
  export OPTION6=4
  export OPTION7=9800
  export OPTION8=false
  export OPTION9=1
  export OPTION10=10
  export OPTION11=false
  setsid ~/bin/lotus-poster run > ~/log/poster.`date +"%m%d%H%M"`.out 2>&1 &
  
  startTryNum=1
  ~/bin/lotus-poster net id
  while [ "$?" != "0" -a $startTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-poster daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/bin/lotus-poster net id
  done
}

function stopall(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-storage-miner"
  kill -9 `ps -u $USER -f | grep lotus-storage-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-slave-miner"
  kill -9 `ps -u $USER -f | grep lotus-storage-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-poster"
  kill -9 `ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus"
  kill -9 `ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps aux | grep lotus | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 2
  done
}

function guard(){
  echo "current user is $USER"
  echo "stop old loGuard.sh"
  kill -9 `ps -u $USER -f | grep loGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start loGuard.sh"
  setsid ~/bin/loGuard.sh $USER > ~/log/loGuard.out 2>&1  &
}

function forceCleanEnv(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .lotus folder"
  if [ -d "/home/$USER/.lotus" ]
    then
        mv ~/.lotus ~/.lotus.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotus does not exist"
  fi

  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .lotusstorage folder"
  if [ -d "/home/$USER/.lotusstorage" ]
    then
        mv ~/.lotusstorage ~/.lotusstorage.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotusstorage does not exist"
  fi

  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .lotusslave folder"
  if [ -d "/home/$USER/.lotusslave" ]
    then
        mv ~/.lotusslave ~/.lotusslave.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotusslave does not exist"
  fi

  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .lotusposter folder"
  if [ -d "/home/$USER/.lotusposter" ]
    then
        mv ~/.lotusposter ~/.lotusposter.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotusposter does not exist"
  fi
}

function forceCleanBin(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "remove lotus"
  if [ -f "/home/$USER/bin/lotus" ]
    then
        rm -rf ~/bin/lotus && echo "----  Deleted"

    else
        echo "----  /home/$USER/bin/lotus does not exist"
  fi

  echo `date +'%Y-%m-%d %H:%M:%S'` "remove lotus-storage-miner"
  if [ -f "/home/$USER/bin/lotus-storage-miner" ]
    then
        rm -rf ~/bin/lotus-storage-miner && echo "----  Deleted"
    else
        echo "----  /home/$USER/bin/lotus-storage-miner does not exist"
  fi

  echo `date +'%Y-%m-%d %H:%M:%S'` "remove lotus-slave-miner"
  if [ -f "/home/$USER/bin/lotus-slave-miner" ]
    then
        rm -rf rm -rf ~/bin/lotus-slave-miner && echo "----  Deleted"
    else
        echo "----  /home/$USER/bin/lotus-slave-miner does not exist"
  fi
}

function info(){
  if [ -n "`ps aux | grep lotus-storage-miner | grep -v grep`" ]
    then
        ~/bin/lotus-storage-miner info
   elif [ -n "`ps aux | grep lotus-slave-miner | grep -v grep`" ]
   then
        ~/bin/lotus-slave-miner info
   else
       echo "Cannot find lotus-storage-miner or lotus-slave-miner process"
  fi
}

function infos(){
  if [ -n "`ps aux | grep lotus-slave-miner | grep -v grep`" ]
    then
        ~/bin/lotus-slave-miner infos
   else
       echo "Cannot find lotus-slave-miner process" 
  fi
}

function peers(){
  if [ -n "`ps aux | grep lotus-storage-miner | grep -v grep`" ]
    then
        echo  "~/bin/lotus net peers ---"
        ~/bin/lotus net peers
        echo -e "\n\n~/bin/lotus-storage-miner net peers ---"
        ~/bin/lotus-storage-miner net peers
   elif [ -n "`ps aux | grep lotus-slave-miner | grep -v grep`" ]
   then
        echo  "~/bin/lotus-poster net peers ---"
        ~/bin/lotus-poster net peers
        echo -e "\n\n~/bin/lotus-slave-miner net peers ---"
        ~/bin/lotus-slave-miner net peers
   else
       echo  "~/bin/lotus net peers ---"
       ~/bin/lotus net peers
  fi
}

function id(){
  if [ -n "`ps aux | grep lotus-storage-miner | grep -v grep`" ]
    then
        echo  "~/bin/lotus net listen ---"
        ~/bin/lotus net listen
        echo -e "\n\n~/bin/lotus-storage-miner net listen ---"
        ~/bin/lotus-storage-miner net listen
   elif [ -n "`ps aux | grep lotus-poster | grep -v grep`" ]
   then
        echo -e "~/bin/lotus-slave-miner net listen ---"
        ~/bin/lotus-slave-miner net listen
        echo -e "\n\n~/bin/lotus-poster net listen ---"
        ~/bin/lotus-poster net listen
   elif [ -n "`ps aux | grep lotus-slave-miner | grep -v grep`" ]
   then
        echo -e "\n\n~/bin/lotus-slave-miner net listen ---"
        ~/bin/lotus-slave-miner net listen
  fi
}

function deal(){
  while true
  do
        echo `date +'%Y-%m-%d %H:%M:%S'` "send a deal"
        ~/bin/lotus-storage-miner pledge-sector &
        sleep $timeInterval
  done
}

case "$1" in
  start|startFull)
        start
        ;;
  mining|startStorage)
        startMiner
        ;;
  slave|startSlave)
        startSlave
        ;;
  poster|startPoster)
        startPoster
        ;;
  restart)
        stopall
        start
        startMiner
        ;;
  restartSlave)
        stopall
        startSlave
        startPoster
        echo $GPU_HASH
        echo $GPU_BELL
        echo $VDE_SWITCH
        ;;
  guard)
        guard
        ;;
  cleanEnv)
        forceCleanEnv
        ;;
  cleanBin)
        forceCleanBin
        ;;
  stopall)
        stopall
        ;;
  log)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep lotus | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any lotus.*.log"
        fi
        ;;
  mlog|logm)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep storage-miner | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any storage-miner.*.log"
        fi
        ;;
  slog|logs)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep slave-miner | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any slave-miner.*.log"
        fi
        ;;
  plog|logp)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep poster | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any poster.*.log"
        fi
        ;;
  wallet)
        ~/bin/lotus wallet balance
        ;;
  info)
        info
        ;;
  infos)
        infos
        ;;
  deal)
        timeInterval=$2
        if [ ! -n "$timeInterval" ];then
                timeInterval=5
        fi
        echo `date +'%Y-%m-%d %H:%M:%S'` "send deal time interval is ${timeInterval} second"
        deal
        ;;
  height)
        ~/bin/lotus sync status
        ;;
  peers)
        peers
        ;;
  id)
        id
        ;;
  prove)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt ~/log | awk '{print $NF}' | grep storage-miner | head -1`
        fi
        #grep -E "scheduling PoSt|submitting PoSt|SubmitPoSt|generate_post:" ~/log/$logFile
        echo "storage miner logFile is "$logFile
        grep "Proving sector" ~/log/$logFile | awk -F':' '{print $1}' | uniq -c
        #grep "updated state to Proving" ~/log/$logFile | awk -F':' '{print $1}' | uniq -c
        ;;
  proves)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt ~/log | awk '{print $NF}' | grep slave-miner | head -1`
        fi
        echo "slave miner logFile is "$logFile
        grep "updated state to Proving" ~/log/$logFile | awk -F':' '{print $1}' | uniq -c
        ;;
  seal)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt ~/log | awk '{print $NF}' | grep storage-miner | head -1`
        fi
        grep -E "seal_sector:|committing sector" ~/log/$logFile
        ;;
  deploy)
        genesisID=$2
        stopall
        forceCleanEnv
        mkdir -p ~/log
        setsid ~/bin/lotus daemon --genesis=/home/$USER/bin/devnet.car  > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
        # wait for lotus daemon up
        startTryNum=1
        res=`~/bin/lotus net id 2>&1`
        failStr="API not running"
        echo $res | grep -q "$failStr"
        while [ $? -eq 0 -a "$startTryNum" -lt 40 ]
        do
                echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus daemon up, try num: $startTryNum"
                let startTryNum++
                sleep 5
                res=`~/bin/lotus net id 2>&1`
                echo $res| grep -q "$failStr"
        done
        if [ -n "$genesisID" ];then
                ~/bin/lotus net connect "$genesisID"
        fi
        ~/bin/lotus wallet new bls
        ;;
  *)
        echo "Usage: ~/bin/view_lotus.sh {start|stopall|mining|slave|restart|restartSlave|cleanEnv|log|logm|logs|id|peers}" || true
        exit 1
esac
exit 0