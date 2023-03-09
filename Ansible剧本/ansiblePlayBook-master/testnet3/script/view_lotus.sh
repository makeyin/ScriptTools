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

function setParam(){
  ###下面适配GPU相关的参数################################################################################
  GpuNumber=`lspci | grep -i vga | grep -i nvidia|wc -l`
  if [[ ${GpuNumber} > 0 ]];then
      export OPTION4=true
      export OPTION5=true
      export OPTION3=9
      export OPTION8=true
  else
      export OPTION4=false
      export OPTION5=false
      export OPTION3=5
      export OPTION8=false
  fi
  if [[ ${GpuNumber} == 1 ]];then
      export OPTION6=[0]
  elif [[ ${GpuNumber} == 2 ]];then
      export OPTION6=[0,1]
  elif [[ ${GpuNumber} == 3 ]];then
      export OPTION6=[0,1,2]
  elif [[ ${GpuNumber} == 4 ]];then
      export OPTION6=[0,1,2,3]
  fi
  echo "OPTION6=${OPTION6}"
  export DISABLE_KAFKA=true
  ###上面适配GPU相关的参数################################################################################
  
  ###下面为4G4U的通用的参数###############################################################################
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=false
  export OPTION9=1
  export OPTION10=0                    #如果设置为0,则是不允许GPU的活给CPU干

  export OPTION11=false                #串行做三棵树和CS（默认false) CPU版本开true
  export OPTION7=10000                  #设置为符合GPU的内存大小,2080Ti的slave设置1w
  export OPTION20=true                 #开启vde cache优化, default is true
  export OPTION12=false                 #走官方的逻辑,如果我们的代码有问题,就开启这个开关,走官方逻辑
  
  export OPTION17=0                    #跑官方VDE版本的数量,增加一个增加64G内存
  export OPTION14=9                    #跑VDE优化版本的数量,Disk版本,一个vde只存32G或64G的数据,如果有nvme则用这个开关,增加一个增加40G内存. OPTION14包含了OPTION15
  export OPTION18=/home/${USER}/vde/          #跟OPTION14配合,nvme的路径,默认有nvme的话路径是/tank3/vde/,没有nvme的话填写None
  export OPTION15=0                    #新增加的nvme即tank4下面可以跑的vde的数量,会将vde的11层全部都存下来,如果没有这个nvme则设置为0,1T设置为2个(11*32G*2<1T),2T设置为5个(11*32G*5<2T).这里面的任务重启会丢失
  export OPTION22=None                 #跟OPTION15配合,新增加的nvme的路径,如果有nvme的话路径是/tank4/vde/,没有新增nvme的话填写None
  export CUSTOMER_NAME=customer_name
  export RELATION_GROUP_NAME=group_name
  ###上面为4G4U的通用的参数###############################################################################
  
  ###下面为AMD机型适配的参数###############################################################################
  if [[ `cat /proc/cpuinfo | grep "model name" | grep AMD` ]] && [[  `df -l | grep tank3` ]]; then
      echo "CPU: AMD processor"
      MemSize=`free -g | grep "Mem" | awk '{print $2}'`
      echo "Mem: ${MemSize}G"
      export OPTION17=0
      echo  "OPTION17=${OPTION17}"
      if [ ${MemSize} -gt 900 ]; then
          export OPTION14=20                    #跑VDE优化版本的数量,Disk版本,一个vde只存32G或64G的数据,如果有nvme则用这个开关,增加一个增加40G内存. OPTION14包含了OPTION15
          echo "OPTION14=${OPTION14}"
      else
          export OPTION14=13                    #跑VDE优化版本的数量,Disk版本,一个vde只存32G或64G的数据,如果有nvme则用这个开关,增加一个增加40G内存. OPTION14包含了OPTION15
          echo "OPTION14=${OPTION14}"
      fi
      export OPTION18=/tank3/vde/            #跟OPTION14配合,nvme的路径,默认有nvme的话路径是/tank3/vde,没有nvme的话填写None
      echo "OPTION18=${OPTION18}"
  fi
  if [[ `cat /proc/cpuinfo | grep "model name" | grep AMD` ]] && [[  `df -l | grep tank4` ]]; then
      export OPTION15=0                     #新增加的nvme即tank4下面可以跑的vde的数量,会将vde的11层全部都存下来,如果没有这个nvme则设置为0,1T设置为2个(11*32G*2<1T),2T设置为5个(11*32G*5<2T).这里面的任务重启会丢失
      export OPTION22=None                  #跟OPTION15配合,新增加的nvme的路径,如果有nvme的话路径是/tank4/vde,没有新增nvme的话填写None
      echo "OPTION15=${OPTION15}"
      echo "OPTION22=${OPTION22}"
  fi
  ###上面为AMD机型适配的参数###############################################################################

  export TRUST_PARAMS=1
  export OPTION23=32 #OPTION23=4

  ###判断不是devnet才需要做这个
  if  [ "${USER}" != "devnet" ];then
      #echo ${USER}
      tmp_folder="/tmp/${USER}_tmp"
      mkdir -p $tmp_folder
      export TMPDIR=${tmp_folder}
  fi
}

function setOspParam(){
  GpuNumber=`lspci | grep -i vga | grep -i nvidia|wc -l`
  if [[ ${GpuNumber} > 0 ]];then
      export OPTION4=true
      export OPTION5=true
      export OPTION3=9
      export OPTION8=true
  else
      export OPTION4=false
      export OPTION5=false
      export OPTION3=5
      export OPTION8=false
  fi
  if [[ ${GpuNumber} == 1 ]];then
      export OPTION6=[0]
  elif [[ ${GpuNumber} == 2 ]];then
      export OPTION6=[0,1]
  elif [[ ${GpuNumber} == 3 ]];then
      export OPTION6=[0,1,2]
  elif [[ ${GpuNumber} == 4 ]];then
      export OPTION6=[0,1,2,3]
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
  ###需要优化,判断不是devnet才需要做这个
  if  [ "${USER}" != "devnet" ];then
      #echo ${USER}
      tmp_folder="/tmp/${USER}_tmp"
      mkdir -p $tmp_folder
      export TMPDIR=${tmp_folder}
  fi
}

function start(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus"
  kill -9 `ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 10
  done
  mkdir -p ~/log

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus daemon"
  rm -f ~/.lotus/repo.lock
  rm -f ~/.lotus/datastore/LOCK
  setParam
  export OPTION20=false
  #BELLMAN_NO_GPU=1
  export RUST_LOG=error
  setsid ~/bin/lotus daemon > ~/log/lotus.`date +"%m%d%H%M"`.out 2>&1 &
  #unset BELLMAN_NO_GPU
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
  while [ -n "`ps -u $USER -f | grep lotus-storage-m | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-storage-miner dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-storage-miner run"
  rm -f ~/.lotusstorage/repo.lock
  rm -f ~/.lotusstorage/datastore/LOCK

  setParam
  #export GOGC=400
  export OPTION20=false
  setsid ~/bin/lotus-storage-miner run > ~/log/storage-miner.`date +"%m%d%H%M"`.out 2>&1 &
  #setsid ~/bin/lotus-storage-miner run --nosync > ~/log/storage-miner.`date +"%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  unset BELLMAN_NO_GPU
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
  while [ -n "`ps -u $USER -f | grep lotus-slave-m | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-slave-miner dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  rm -f ~/.lotusslave/repo.lock
  rm -f ~/.lotusslave/datastore/LOCK
  sleep 5
  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-slave-miner run"
  setParam
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

  rm -f ~/.wdsnarker/repo.lock
  rm -f ~/.wdsnarker/datastore/LOCK
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
function startWindowPost(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-worker"
  kill -9 `ps -u $USER -f | grep osp-window | grep -v grep | awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep osp-window | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp-worker dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  rm -f ~/.ospworker/repo.lock
  sleep 2
  echo `date +'%Y-%m-%d %H:%M:%S'` "start osp-provider run"
  setParam
  setsid ~/bin/osp-window  daemon > ~/log/osp-window.`date +"%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  ~/bin/osp-window net id
  while [ "$?" != "0" -a $startTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for osp-window daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 10
      ~/bin/osp-window net id
  done

}
function startPoster(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-poster"
  #kill `ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'` 2> /dev/null
  ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'|xargs kill -9  2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus-poster | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-poster dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 10
  done

  rm -f ~/.lotusposter/repo.lock
  rm -f ~/.lotusposter/datastore/LOCK
  sleep 5
  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-poster run"
  setParam
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
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop filGuard"
  kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-storage-miner"
  kill -9 `ps -u $USER -f | grep lotus-storage-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-slave-miner"
  kill -9 `ps -u $USER -f | grep lotus-storage-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-poster"
  kill -9 `ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus"
  kill -9 `ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 3
  done
}

function masterGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh master >> ~/log/filGuard.out 2>&1  &
    else
        echo -e "\033[31m没有filGuard文件\033[0m"
  fi
}

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

function posterGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-poster"
  kill -9 `ps -u $USER -f | grep "filGuard.sh poster" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh-poster"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh poster >> ~/log/filGuard.out 2>&1  &
    else
        echo -e "\033[31m没有filGuard文件\033[0m"
  fi

}

function stopSlaveGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-slave"
  kill -9 `ps -u $USER -f | grep "filGuard.sh slave" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopPosterGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-poster"
  kill -9 `ps -u $USER -f | grep "filGuard.sh poster" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopallosp(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-provider "
  kill -9 `ps -u $USER -f | grep osp-provider | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-worker"
  kill -9 `ps -u $USER -f | grep osp-worker | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop osp-window"
  kill -9 `ps -u $USER -f | grep osp-window | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
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
  echo "start filGuard.sh"
  setsid ~/bin/ospGuard.sh worker >> ~/log/ospGuard.out 2>&1  &
}

function stopProviderGuard(){
  echo "current user is $USER"
  echo "stop old ospGuard-provider"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh provider" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopWorkerGuard(){
  echo "current user is $USER"
  echo "stop old ospGuard-provider"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh worker" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function forceCleanEnv(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .lotus folder"
  if [ -d "/home/$USER/.lotus" ]
    then
        mv ~/.lotus ~/.lotus.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotus does not exist"
  fi

  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .wdsnarker folder"
  if [ -d "/home/$USER/.wdsnarker" ]
    then
        mv ~/.wdsnarker ~/.wdsnarker.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.wdsnarker does not exist"
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

function CleanOspWindowEnv(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .wdsnarker folder"
  if [ -d "/home/$USER/.wdsnarker" ]
    then
        mv ~/.wdsnarker ~/.wdsnarker`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.wdsnarker does not exist"
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

  echo `date +'%Y-%m-%d %H:%M:%S'` "remove lotus-poster-miner"
  if [ -f "/home/$USER/bin/lotus-poster-miner" ]
    then
        rm -rf rm -rf ~/bin/lotus-poster-miner && echo "----  Deleted"
    else
        echo "----  /home/$USER/bin/lotus-poster-miner does not exist"
  fi
}

function info(){
  if [ -n "`ps -u $USER -f | grep lotus-storage-miner | grep -v grep`" ]
    then
        ~/bin/lotus-storage-miner info
   elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
   then
        ~/bin/lotus-slave-miner info
   else
       echo "Cannot find lotus-storage-miner or lotus-slave-miner process"
  fi
}

function infos(){
  if [ -n "`ps -u $USER -f | grep lotus-storage-miner | grep -v grep`" ]
    then
        echo  "~/bin/lotus-storage-miner infos ---"
        ~/bin/lotus-storage-miner infos
   elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
   then
        echo  "~/bin/lotus-slave-miner infos ---"
        ~/bin/lotus-slave-miner infos
   else
       echo "Cannot find lotus-storage-miner or lotus-slave-miner process"
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

function peers(){
  if [ -n "`ps -u $USER -f | grep lotus-storage-miner | grep -v grep`" ]
    then
        echo  "~/bin/lotus net peers ---"
        ~/bin/lotus net peers
        echo -e "\n\n~/bin/lotus-storage-miner net peers ---"
        ~/bin/lotus-storage-miner net peers
   elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
   then
        echo  "~/bin/lotus-poster net peers ---"
        ~/bin/lotus-poster net peers
        echo -e "\n\n~/bin/lotus-slave-miner net peers ---"
        ~/bin/lotus-slave-miner net peers
   elif [ -n "`ps -u $USER -f | grep osp-window | grep -v grep`" ]
   then
        echo  "~/bin/osp-window net peers ---"
        ~/bin/osp-window net peers
        echo -e "\n\n~/bin/osp-window net peers ---"
        ~/bin/osp-window net peers
   else
       echo  "~/bin/lotus net peers ---"
       ~/bin/lotus net peers
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

function id(){
  if [ -n "`ps -u $USER -f | grep lotus-storage-miner | grep -v grep`" ]
    then
        echo  "~/bin/lotus net listen ---"
        ~/bin/lotus net listen
        echo -e "\n~/bin/lotus-storage-miner net listen ---"
        ~/bin/lotus-storage-miner net listen
  elif [ -n "`ps -u $USER -f | grep "lotus daemon"  | grep -v grep`" ]
    then
        echo  "~/bin/lotus net listen ---"
        ~/bin/lotus net listen
  fi

  if [ -n "`ps -u $USER -f | grep lotus-poster | grep -v grep`" ]
    then
        echo -e "~/bin/lotus-slave-miner net listen ---"
        ~/bin/lotus-slave-miner net listen
        echo -e "\n~/bin/lotus-poster net listen ---"
        ~/bin/lotus-poster net listen
  elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-slave-miner net listen ---"
        ~/bin/lotus-slave-miner net listen
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

  if [ -n "`ps -u $USER -f | grep osp-window | grep -v grep`" ]
    then
        echo -e "~/bin/osp-window net listen ---"
        ~/bin/osp-window net listen
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

function stopGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null
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

function startwindowGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh window" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start ospGuard.sh"
  setsid ~/bin/ospGuard.sh window >> ~/log/ospGuard.out 2>&1  &
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

function stopwindowGuard(){
  echo "current user is $USER"
  echo "stop old ospGuard-window"
  kill -9 `ps -u $USER -f | grep "ospGuard.sh window" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

case "$1" in
  start|startFull)
        stopall
        start
        ;;
  mining|startStorage)
        stopGuard
        startMiner
        masterGuard
        ;;
  slave|startSlave)
        stopSlaveGuard
        startSlave
        slaveGuard
        ;;
  poster|startPoster)
        stopPosterGuard
        startPoster
        posterGuard
        ;;
 wp|startwindow)
        stopwindowGuard
        startWindowPost
        startwindowGuard
        ;;
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
  restart)
        stopall
        start
        startMiner
        masterGuard
        ;;
  restartSlave)
        stopall
        startPoster
        startSlave
        slaveGuard
        echo $GPU_HASH
        echo $GPU_BELL
        echo $VDE_SWITCH
        ;;
  mguard)
        masterGuard
        ;;
  sguard)
        slaveGuard
        ;;
  pguard)
        startProviderGuard
        ;;
  wguard)
        startWorkerGuard
        ;;        
  stopguard)
        stopGuard
        ;;
  cleanEnv)
        forceCleanEnv
        ;;
  cleanWorker)
        forceCleanOspWorkerEnv
        ;;
   cleanwindow)
        CleanOspWindowEnv
        ;;
  cleanProvider)
        forceCleanOspProviderEnv
        ;;
  stopWorker)
        stopospworker
        ;;
  stopProvider)
        stopospprovider
        ;;
  cleanOspEnv)
        forceCleanOspEnv
        ;;
  cleanBin)
        forceCleanBin
        ;;
  stopall)
        stopall
        ;;
  stopallosp)
        stopallosp
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
  tailm)
        tail -f ~/log/`ls -lt ~/log | awk '{print $NF}' | grep storage-miner | head -1` | egrep "mined new block|mineoneSep|received w-tasks|loop"
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
  wdlog|logwd)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep osp-window | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any osp-window.*.log"
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
  infow)
        infow
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
  osppeers)
        osppeers
        ;;
  id)
        id
        ;;
  ospid)
        ospid
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
#        grep "updated state to Proving" ~/log/$logFile | awk -F':' '{print $1}' | uniq -c
        grep "updated state to CommitWait" ~/log/$logFile | awk '!Sector[$6]++{print}' | awk -F':' '{print $1}' | uniq -c
        ;;
  seal)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt ~/log | awk '{print $NF}' | grep storage-miner | head -1`
        fi
        grep -E "seal_sector:|committing sector" ~/log/$logFile
        ;;
  pinfo)
       ~/bin/lotus-miner proving info
       ;;
  pwd)
       ~/bin/lotus-miner proving deadlines
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
        ~/bin/lotus wallet new blsF
        ;;
  *)
        echo "Usage: ~/bin/view_lotus.sh {start|stopall|mining|slave|restart|restartSlave|cleanEnv|log|logm|logs|id|peers}" || true
        exit 1
esac
exit 0