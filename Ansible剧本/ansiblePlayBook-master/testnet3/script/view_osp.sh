#!/bin/bash
##  设置 alias vl="~/bin/view_lotus.sh"
#set -x

function getModel(){
  ###机型分为
  ### a. 4G4U
  ### b. AMD1T2T_MEM1T
  ### c. AMD1T2T_MEM512G
  ### d. 2G2U
  ### e. OTHER

  if [[ `cat /proc/cpuinfo | grep "model name" | grep AMD` ]]; then
      echo "AMD processor"
      if [ `free -g | grep "Mem" | awk '{print $2}'` -gt 900 ]; then
          echo "has 1T mem"
          if [[  `df -l | grep tank4` ]];then
              echo "has tank4"
          fi
      else
          echo "has 512 mem"
      fi

  elif [[ `cat /proc/cpuinfo | grep "model name" | grep Intel` ]]; then
          echo "Intel processor"
  fi

}

function setOspParam(){
  GpuNumber=`lspci | grep -i vga | grep -i nvidia|wc -l`
  if [[ ${GpuNumber} > 0 ]];then
      export OPTION4=true
      export OPTION5=true
      export OPTION3=2
      export OPTION8=true
  else
      export OPTION4=false
      export OPTION5=false
      export OPTION3=2
      export OPTION8=false
  fi
  if  [ "${USER}" = "devnet" ];then
          export OPTION6=[0]
  fi
  if  [ "${USER}" = "testnet" ];then
          export OPTION6=[1]
  fi
  if  [ "${USER}" = "filecoin" ];then
          export OPTION6=[2]
  fi
  if  [ "${USER}" = "mainnet" ];then
          export OPTION6=[3]
  fi
  #echo -e "\033[32m**********可变参数打印**********\033[0m"
  echo "OPTION6=${OPTION6}"

  ###下面为通用的参数
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=false
  export OPTION7=10500
  export OPTION8=false
  export OPTION9=0
  export OPTION10=0
  export OPTION11=false
  export OPTION14=0
  export OPTION15=0
  export OPTION17=0
  export OPTION20=false
  export RELATION_GROUP_NAME=group_name
  export CUSTOMER_NAME=customer_name
  echo "OPTION3=${OPTION3}"
  ###需要优化,判断不是devnet才需要做这个
  if  [ "${USER}" != "devnet" ];then
      #echo ${USER}
      tmp_folder="/tmp/${USER}_tmp"
      mkdir -p $tmp_folder
      export TMPDIR=${tmp_folder}
  fi
}

function startProvider(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-provider"
  kill -9 `ps -u $USER -f | grep osp-provider | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep osp-provider | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp-provider dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  rm -f ~/.ospprovider/repo.lock
  rm -f ~/.ospprovider/datastore/LOCK
  sleep 5
  echo `date +'%Y-%m-%d %H:%M:%S'` "start osp-provider run"
  setOspParam
  setsid ~/bin/osp-provider  daemon > ~/log/osp-provider.`date +"%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  ~/bin/osp-provider net id
  while [ "$?" != "0" -a $startTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp-provider daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/bin/osp-provider net id
  done
}

function startWorker(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-worker"
  kill -9 `ps -u $USER -f | grep osp-worker | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep osp-worker | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp-worker dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  rm -f ~/.ospworker/repo.lock
  rm -f ~/.ospworker/datastore/LOCK
  sleep 5
  echo `date +'%Y-%m-%d %H:%M:%S'` "start osp-provider run"
  setOspParam
  setsid ~/bin/osp-worker  daemon > ~/log/osp-worker.`date +"%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  ~/bin/osp-worker net id
  while [ "$?" != "0" -a $startTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp-worker daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/bin/osp-worker net id
  done
}

function initWorker(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "start osp-provider run"
  setOspParam
  setsid ~/bin/osp-worker  daemon > ~/log/osp-worker.`date +"%m%d%H%M"`.out 2>&1 &
  sleep 10
}

function stopallosp(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-provider "
  kill -9 `ps -u $USER -f | grep osp-provider | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-worker"
  kill -9 `ps -u $USER -f | grep osp-worker | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep osp | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 2
  done
}

function stopospworker(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-worker"
  kill -9 `ps -u $USER -f | grep osp-worker | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep osp-worker | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 2
  done
}

function stopospprovider(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-provider"
  kill -9 `ps -u $USER -f | grep osp-provider | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep osp-provider | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 2
  done
}


function forceCleanOspEnv(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .osp-provider folder"
  if [ -d "/home/$USER/.ospprovider" ]
    then
        mv ~/.ospprovider ~/.ospprovider.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.ospprovider does not exist"
  fi
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .ospworker folder"
  if [ -d "/home/$USER/.ospworker" ]
    then
        mv ~/.ospworker ~/.ospworker.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.ospworker does not exist"
  fi
}

function forceCleanOspProviderEnv(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .osp-provider folder"
  if [ -d "/home/$USER/.ospprovider" ]
    then
        mv ~/.ospprovider ~/.ospprovider.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.ospprovider does not exist"
  fi
}

function forceCleanOspWorkerEnv(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .ospworker folder"
  if [ -d "/home/$USER/.ospworker" ]
    then
        mv ~/.ospworker ~/.ospworker.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.ospworker does not exist"
  fi
}

function infow(){
  if [ -n "`ps -u $USER -f | grep osp-worker | grep -v grep`" ]
    then
        echo  "~/bin/osp-worker info ---"
        ~/bin/osp-worker info
   else
       echo "Cannot find osp-worker process"
  fi
}


function osppeers(){
  if [ -n "`ps -u $USER -f | grep osp-provider | grep -v grep`" ]
    then
        echo  "~/bin/osp-provider net peers ---"
        ~/bin/osp-provider net peers
  fi
  if [ -n "`ps -u $USER -f | grep osp-worker | grep -v grep`" ]
   then
        echo  "~/bin/osp-worker net peers ---"
        ~/bin/osp-worker net peers
  fi
}


function ospid(){
  if [ -n "`ps -u $USER -f | grep osp-provider | grep -v grep`" ]
    then
        echo  "~/bin/osp-provider net listen ---"
        ~/bin/osp-provider net listen
  fi

  if [ -n "`ps -u $USER -f | grep osp-worker | grep -v grep`" ]
    then
        echo -e "~/bin/osp-worker net listen ---"
        ~/bin/osp-worker net listen
  fi
}


function startProviderGuard(){
  echo "current user is $USER"
  echo "stop old ospGuard.sh"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh provider" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start ospGuard.sh"
  setsid ~/bin/ospGuard.sh provider >> ~/log/ospGuard.out 2>&1  &
}

function startWorkerGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh worker" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start ospGuard.sh"
  setsid ~/bin/ospGuard.sh worker >> ~/log/ospGuard.out 2>&1  &
}

function stopProviderGuard(){
  echo "current user is $USER"
  echo "stop old ospGuard-provider"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh provider" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopWorkerGuard(){
  echo "current user is $USER"
  echo "stop old ospGuard-worker"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh worker" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

case "$1" in
  op|provider)
        stopProviderGuard
        startProvider
        startProviderGuard
        ;;
  ow|worker)
        stopWorkerGuard
        startWorker
        startWorkerGuard
        ;;
  pguard)
        startProviderGuard
        ;;
  wguard)
        startWorkerGuard
        ;;
  cleanWorker)
        forceCleanOspWorkerEnv
        ;;
  cleanProvider)
        forceCleanOspProviderEnv
        ;;
  stopWorker)
        stopWorkerGuard
        stopospworker
        ;;
  stopProvider)
        stopProviderGuard
        stopospprovider
        ;;
  cleanOspEnv)
        forceCleanOspEnv
        ;;
  stopallosp)
        stopProviderGuard
        stopWorkerGuard
        stopallosp
        ;;
  dlog|logd)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep osp-provider | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any osp-provider.*.log"
        fi
        ;;
  wlog|logw)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep osp-worker | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any osp-worker.*.log"
        fi
        ;;
  infow)
        infow
        ;;
  osppeers)
        osppeers
        ;;
  ospid)
        ospid
        ;;
  initWorker)
        initWorker
        ;;
  *)
        echo "Usage: ~/bin/view_lotus.sh {op|ow|logd|logw|ospid|osppeers|cleanProvider|cleanWorker|stopallosp}" || true
        exit 1
esac
exit 0