#!/bin/bash
##  设置 alias vl="~/bin/view_lotus.sh"
#set -x

function setParam(){
  ###下面适配GPU相关的参数################################################################################
  #GpuNumber=`lspci | grep -i vga | grep -i nvidia|wc -l`
  GpuNumber=`nvidia-smi -L|grep GPU |wc -l`
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

  Nvid=`nvidia-smi -L|awk '{print $3,$4,$5,$6}'`
  echo "${Nvid}"| grep 'GeForce RTX 2080 Ti'
  if [ $? -eq 0 ];then
      export OPTION7=10000
  fi
  echo "${Nvid}"| grep 'GeForce RTX 2060 SUPER'
  if [ $? -eq 0 ];then
      export OPTION7=7000
  fi
  echo "${Nvid}"| grep 'GeForce RTX 2070 SUPER'
  if [ $? -eq 0 ];then
      export OPTION7=7000
  fi
  echo "OPTION7: $OPTION7"
  ###上面适配GPU相关的参数################################################################################

  ###下面为4G4U的通用的参数###############################################################################
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=false
  export OPTION9=1
  export OPTION10=0                    #如果设置为0,则是不允许GPU的活给CPU干
  export OPTION11=false                #串行做三棵树和CS（默认false) CPU版本开true
  #export OPTION7=10000                  #设置为符合GPU的内存大小,2080Ti的slave设置1w
  export OPTION20=true                 #开启vde cache优化, default is true
  export OPTION12=false                 #走官方的逻辑,如果我们的代码有问题,就开启这个开关,走官方逻辑

  export OPTION17=0                    #跑官方VDE版本的数量,增加一个增加64G内存
  export OPTION14=9                    #跑VDE优化版本的数量,Disk版本,一个vde只存32G或64G的数据,如果有nvme则用这个开关,增加一个增加40G内存. OPTION14包含了OPTION15
  export OPTION18=None          #跟OPTION14配合,nvme的路径,默认有nvme的话路径是/tank3/vde/,没有nvme的话填写None
  export OPTION15=0                    #新增加的nvme即tank4下面可以跑的vde的数量,会将vde的11层全部都存下来,如果没有这个nvme则设置为0,1T设置为2个(11*32G*2<1T),2T设置为5个(11*32G*5<2T).这里面的任务重启会丢失
  export OPTION22=None                #跟OPTION15配合,新增加的nvme的路径,如果有nvme的话路径是/tank4/vde/,没有新增nvme的话填写None
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
      if [ ${MemSize} -gt 1300 ]; then
          export OPTION14=30                    #跑VDE优化版本的数量,Disk版本,一个vde只存32G或64G的数据,如果有nvme则用这个开关,增加一个增加40G内存. OPTION14包含了OPTION15
          echo "OPTION14=${OPTION14}"
      elif [ ${MemSize} -gt 900 ]; then
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
      export OPTION15=4                     #新增加的nvme即tank4下面可以跑的vde的数量,会将vde的11层全部都存下来,如果没有这个nvme则设置为0,1T设置为2个(11*32G*2<1T),2T设置为5个(11*32G*5<2T).这里面的任务重启会丢失
      export OPTION22=None                  #跟OPTION15配合,新增加的nvme的路径,如果有nvme的话路径是/tank4/vde,没有新增nvme的话填写None
      echo "OPTION15=${OPTION15}"
      echo "OPTION22=${OPTION22}"
  fi
  ###上面为AMD机型适配的参数###############################################################################

  export TRUST_PARAMS=1
  export DISABLE_KAFKA=true
  export OPTION23=32 #OPTION23=4

  ###判断不是devnet才需要做这个
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
  export OPTION26=32
  #export DISABLE_SYNC_USE_CACHE=false
  setsid ~/bin/lotus daemon > ~/log/lotus.`date +"%Y%m%d%H%M"`.out 2>&1 &
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
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-power"
  kill -9 `ps -u $USER -f | grep lotus-power | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-power dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-power run"
  rm -f ~/.lotusminer/repo.lock
  rm -f ~/.lotusminer/datastore/LOCK

  setParam
  #export GOGC=400
  export OPTION20=false
  #export OPTION_USE_WAIT_MESSAGE_CHAN=true
  #export LOTUS_PRECOMMITCHANLIMIT=16
  #export LOTUS_COMMITCHANLIMIT=12
  export OPTION_ENABLE_RETRY_PUSH_MESSAGE=true  #消息上链因为抵押无不足败了会自动重试上链
  #export OPTION_DISABLE_PRECOMMITTING=false
  #export OPTION_DISABLE_COMMITTING=false
  setsid ~/bin/lotus-power run > ~/log/lotus-power.`date +"%Y%m%d%H%M"`.out 2>&1 &
  #setsid ~/bin/lotus-power run --nosync > ~/log/lotus-power.`date +"%Y%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  unset BELLMAN_NO_GPU
  ~/bin/lotus-power net id
  while [ "$?" != "0" -a $startTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-power daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 20
      ~/bin/lotus-power net id
  done
  #echo `date +'%Y-%m-%d %H:%M:%S'` "mpool setconfig"
  #~/bin/lotus mpool setconfig --proven 800 --pre 1000 --window 1000 --deal 1000 --other 1500
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
  setsid ~/bin/lotus-slave-miner run > ~/log/slave-miner.`date +"%Y%m%d%H%M"`.out 2>&1 &

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

function startWindowPoster(){
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
  export QINIU=/home/$USER/.lotusposter/c.toml
  export QINIU_CHECK_SECTOR=/home/$USER/.lotusposter/s.json
  #export PARALLEL_VANILLA_FROM_GO=yes
  #export MAXREQS=256
  setsid ~/bin/lotus-poster run > ~/log/poster.`date +"%Y%m%d%H%M"`.out 2>&1 &

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
  
  if [ -f /home/$USER/.lotusposter/c.toml ];then
      export QINIU=/home/$USER/.lotusposter/c.toml
      export QINIU_CHECK_SECTOR=/home/$USER/.lotusposter/s.json
  fi
  echo "export QINIU="$QINIU
  setsid ~/bin/lotus-poster run > ~/log/poster.`date +"%Y%m%d%H%M"`.out 2>&1 &

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

function startwindow(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-window "
  kill -9 `ps -u $USER -f | grep lotus-window  | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus-window  | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-window  dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-window  run"
  setParam
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export NO_NEED_DETECTED_FAULT=no
  export NO_NEED_DECLARE_FAULT=yes
  setsid ~/bin/lotus-window  run > ~/log/lotus-window.`date +"%Y%m%d%H%M"`.out 2>&1 &
  #setsid ~/bin/lotus-window  run --nosync > ~/log/lotus-window .`date +"%Y%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  unset BELLMAN_NO_GPU
  ~/bin/lotus-window  net id
  while [ "$?" != "0" -a $startTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-window  daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 20
      ~/bin/lotus-window  net id
  done
  #echo `date +'%Y-%m-%d %H:%M:%S'` "mpool setconfig"
  #~/bin/lotus mpool setconfig --proven 800 --pre 1000 --window 1000 --deal 1000 --other 1500
}

function startwinning(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-winning"
  kill -9 `ps -u $USER -f | grep lotus-winning | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus-winning | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-winning dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 20
  done

  echo `date +'%Y-%m-%d %H:%M:%S'` "start lotus-winning run"
  rm -f ~/.lotusminer/repo.lock
  rm -f ~/.lotusminer/datastore/LOCK
  setParam
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  setsid ~/bin/lotus-winning run > ~/log/lotus-winning.`date +"%Y%m%d%H%M"`.out 2>&1 &
  #setsid ~/bin/lotus-winning run --nosync > ~/log/lotus-winning.`date +"%Y%m%d%H%M"`.out 2>&1 &

  startTryNum=1
  unset BELLMAN_NO_GPU
  ~/bin/lotus-winning net id
  while [ "$?" != "0" -a $startTryNum -lt 10 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus-winning daemon up, try num: $startTryNum"
      let startTryNum++
      sleep 20
      ~/bin/lotus-winning net id
  done
  #echo `date +'%Y-%m-%d %H:%M:%S'` "mpool setconfig"
  #~/bin/lotus mpool setconfig --proven 800 --pre 1000 --window 1000 --deal 1000 --other 1500
}


function stopall(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop filGuard"
  kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-power"
  kill -9 `ps -u $USER -f | grep lotus-power | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-slave-miner"
  kill -9 `ps -u $USER -f | grep lotus-slave-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-poster"
  kill -9 `ps -u $USER -f | grep lotus-poster | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-window"
  kill -9 `ps -u $USER -f | grep lotus-window | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-winning"
  kill -9 `ps -u $USER -f | grep lotus-winning | grep -v grep | awk '{print $2}'` 2> /dev/null

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

function stopslave(){
  echo `date +'%Y-%m-%d %H:%M:%S'` "stop filGuard"
  kill -9 `ps -u $USER -f | grep "filGuard.sh slave" | grep -v grep | awk '{print $2}'` 2> /dev/null

  echo `date +'%Y-%m-%d %H:%M:%S'` "stop lotus-slave-miner"
  kill -9 `ps -u $USER -f | grep lotus-slave-miner | grep -v grep | awk '{print $2}'` 2> /dev/null

  stopTryNum=1
  while [ -n "`ps -u $USER -f | grep lotus | grep -v grep | grep -v view_lotus.sh`" -a $stopTryNum -lt 20 ]
  do
      echo `date +'%Y-%m-%d %H:%M:%S'` " wait for lotus dying out,  try num: $stopTryNum"
      let stopTryNum++
      sleep 3
  done
}

function fullnodeGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep filGuard.sh fullNonde | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh fullNonde >> ~/log/filGuard.out 2>&1  &
    else
        echo -e "\033[31m没有filGuard文件\033[0m"
  fi
}

function powerGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep "filGuard.sh power" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh power >> ~/log/filGuard.out 2>&1  &
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

function windowGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-window"
  kill -9 `ps -u $USER -f | grep "filGuard.sh window" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh-window"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh window >> ~/log/filGuard.out 2>&1  &
    else
        echo -e "\033[31m没有filGuard文件\033[0m"
  fi

}

function winningGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-winning"
  kill -9 `ps -u $USER -f | grep "filGuard.sh winning" | grep -v grep | awk '{print $2}'` 2> /dev/null
  echo "start filGuard.sh-winning"
  if [ -f "/home/$USER/bin/filGuard.sh" ]
    then
        setsid ~/bin/filGuard.sh winning >> ~/log/filGuard.out 2>&1  &
    else
        echo -e "\033[31m没有filGuard文件\033[0m"
  fi
}

function stopFullnodeGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-slave"
  kill -9 `ps -u $USER -f | grep "filGuard.sh fullNonde" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopPowerGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-slave"
  kill -9 `ps -u $USER -f | grep "filGuard.sh power" | grep -v grep | awk '{print $2}'` 2> /dev/null
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

function stopWindowGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-window"
  kill -9 `ps -u $USER -f | grep "filGuard.sh window" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopWiningGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh-winning"
  kill -9 `ps -u $USER -f | grep "filGuard.sh winning" | grep -v grep | awk '{print $2}'` 2> /dev/null
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

  echo `date +'%Y-%m-%d %H:%M:%S'` "bakup .lotusminer folder"
  if [ -d "/home/$USER/.lotusminer" ]
    then
        mv ~/.lotusminer ~/.lotusminer.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotusminer does not exist"
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

  if [ -d "/home/$USER/.lotuswinning" ]
    then
        mv ~/.lotuswinning ~/.lotuswinning.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotuswinning does not exist"
  fi

  if [ -d "/home/$USER/.lotuswindow" ]
    then
        mv ~/.lotuswindow ~/.lotuswindow.`date +%m%d%H%M` && echo "----  Success!"
    else
        echo "----  /home/$USER/.lotuswindow does not exist"
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

  echo `date +'%Y-%m-%d %H:%M:%S'` "remove lotus-power"
  if [ -f "/home/$USER/bin/lotus-power" ]
    then
        rm -rf ~/bin/lotus-power && echo "----  Deleted"
    else
        echo "----  /home/$USER/bin/lotus-power does not exist"
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
  if [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep`" ]
    then
        ~/bin/lotus-power info
   elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
   then
        ~/bin/lotus-slave-miner info
   elif [ -n "`ps -u $USER -f | grep lotus-winning | grep -v grep`" ]
   then
        echo  "~/bin/lotus-winning info ---"
        ~/bin/lotus-winning info
   else
       echo "Cannot find lotus-power or lotus-slave-miner process"
  fi
}

function infos(){
  if [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep`" ]
    then
        echo  "~/bin/lotus-power infos ---"
        ~/bin/lotus-power infos
   elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
   then
        echo  "~/bin/lotus-slave-miner infos ---"
        ~/bin/lotus-slave-miner infos

   else
       echo "Cannot find lotus-power or lotus-slave-miner process"
  fi
}


function peers(){
  if [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep`" ]
    then
        echo  "~/bin/lotus net peers ---"
        ~/bin/lotus net peers
        echo -e "\n\n~/bin/lotus-power net peers ---"
        ~/bin/lotus-power net peers
   elif [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
   then
        echo  "~/bin/lotus-poster net peers ---"
        ~/bin/lotus-poster net peers
        echo -e "\n\n~/bin/lotus-slave-miner net peers ---"
        ~/bin/lotus-slave-miner net peers
   elif [ -n "`ps -u $USER -f | grep lotus-window | grep -v grep`" ]
   then
        echo  "~/bin/lotus-window net peers ---"
        ~/bin/lotus-window net peers
        echo -e "\n\n~/bin/lotus-window net peers ---"
        ~/bin/lotus-window net peers
   elif [ -n "`ps -u $USER -f | grep lotus-winning | grep -v grep`" ]
   then
        echo  "~/bin/lotus-winning net peers ---"
        ~/bin/lotus-winning net peers
        echo -e "\n\n~/bin/olotus-winning net peers ---"
        ~/bin/lotus-winning net peers

   else
       echo  "~/bin/lotus net peers ---"
       ~/bin/lotus net peers
  fi
}

function id(){

  if [ -n "`ps -u $USER -f | grep "lotus daemon"  | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus net listen ---"
        ~/bin/lotus net listen
  fi

  if [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-power net listen ---"
        ~/bin/lotus-power net listen
  fi

  if [ -n "`ps -u $USER -f | grep lotus-poster | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-poster net listen ---"
        ~/bin/lotus-poster net listen
  fi

  if [ -n "`ps -u $USER -f | grep lotus-slave-miner | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-slave-miner net listen ---"
        ~/bin/lotus-slave-miner net listen
  fi

  if [ -n "`ps -u $USER -f | grep lotus-winning | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-winning net listen ---"
        ~/bin/lotus-winning net listen
  fi

  if [ -n "`ps -u $USER -f | grep lotus-window | grep -v grep`" ]
    then
        echo -e "\n~/bin/lotus-window net listen ---"
        ~/bin/lotus-window net listen
  fi
}

function pwd(){
  if [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep`" ]
    then
        echo  "~/bin/lotus-power proving deadlines ---"
        ~/bin/lotus-power proving deadlines
        exit 0
   elif [ -n "`ps -u $USER -f | grep lotus-window | grep -v grep`" ]
   then
        echo  "~/bin/lotus-window proving deadlines ---"
        ~/bin/lotus-window proving deadlines
        exit 0
   elif [ -n "`ps -u $USER -f | grep lotus-winning | grep -v grep`" ]
   then
        echo  "~/bin/lotus-winning proving deadlines ---"
        ~/bin/lotus-winning proving deadlines
  fi
}

function pinfo(){
  if [ -n "`ps -u $USER -f | grep lotus-power | grep -v grep`" ]
    then
        echo  "~/bin/lotus-power proving info ---"
        ~/bin/lotus-power proving info
        exit 0
   elif [ -n "`ps -u $USER -f | grep lotus-window | grep -v grep`" ]
   then
        echo  "~/bin/lotus-window proving info ---"
        ~/bin/lotus-window proving info
        exit 0
   elif [ -n "`ps -u $USER -f | grep lotus-winning | grep -v grep`" ]
   then
        echo  "~/bin/lotus-winning proving info ---"
        ~/bin/lotus-winning proving info
  fi
}

function stopGuard(){
  echo "current user is $USER"
  echo "stop old filGuard.sh"
  kill -9 `ps -u $USER -f | grep filGuard.sh | grep -v grep | awk '{print $2}'` 2> /dev/null
}

case "$1" in
  start|startFull)
        stopFullnodeGuard
        start
        fullnodeGuard
        ;;
  mining|power)
        stopPowerGuard
        startMiner
        powerGuard
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
  wposter|startWindowPoster)
        stopPosterGuard
        startWindowPoster
        posterGuard
        ;;
  wn|winning)
        stopWiningGuard
        startwinning
        winningGuard
        ;;
  wp|window)
        stopWindowGuard
        startwindow
        windowGuard
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
  stopguard)
        stopGuard
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
  stopsalve)
        stopslave
        ;;
  log)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep "lotus[.]" | head  -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any lotus.*.log"
        fi
        ;;
  mlog|logm)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep lotus-power | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any lotus-power.*.log"
        fi
        ;;
  tailm)
        tail -f ~/log/`ls -lt ~/log | awk '{print $NF}' | grep lotus-power | head -1` | egrep "mined new block|mineoneSep|received w-tasks|loop"
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
  wnlog|logwn)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep lotus-winning | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any lotus-winning.*.log"
        fi
        ;;
  wdlog|logwd)
        logfile=`ls -lt ~/log | awk '{print $NF}' | grep lotus-window | head -1`
        if [ -n "$logfile" ];then
                less ~/log/$logfile
            else
                echo "Cannot find any lotus-window.*.log"
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
            logFile=`ls -lt ~/log | awk '{print $NF}' | grep lotus-power | head -1`
        fi
        #grep -E "scheduling PoSt|submitting PoSt|SubmitPoSt|generate_post:" ~/log/$logFile
        echo "lotus miner logFile is "$logFile
        grep "Proving sector" ~/log/$logFile | awk '!sector[$7]++{print}' |awk -F':' '{print $1}' | uniq -c
        #grep "updated state to Proving" ~/log/$logFile | awk -F':' '{print $1}' | uniq -c
        ;;
  check)
        hours=$2
        if [ ! -n "$hours" ];then
                hours=16
        fi
        miner=`~/bin/lotus-power info | grep "Miner: " | awk '{print $2}'`
        ~/bin/lotus state sectors-check --after-hours ${hours} --addrs ${miner}
        ~/bin/lotus state sectors-check --after-hours ${hours} --addrs ${miner} | grep ago | awk '{print $2}' > over
        rm -f tmp_over; for i in `cat over`;do echo $i `~/bin/lotus-power sectors status $i| grep "Status" | awk '{print $2}'` `~/bin/lotus-power sectors status $i| grep "SlavePeer" | awk '{print $2}'` `~/bin/lotus-power sectors status --log $i| grep "invalid proof"` >> tmp_over ;done;
        if [ -f tmp_over ];then
            echo -e "\033[31m $hours小时内快过期的扇区状态信息: \033[0m"
            cat tmp_over
        else
            echo -e "\033[34m $hours小时内快过期的扇区状态信息: 无\033[0m"
        fi
        ;;
  proves)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt ~/log | awk '{print $NF}' | grep slave-miner | head -1`
        fi
        echo "slave miner logFile is "$logFile
        grep "Proving sector" ~/log/$logFile | awk '!sector[$7]++{print}' |awk -F':' '{print $1}' | uniq -c
        ;;
  seal)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt ~/log | awk '{print $NF}' | grep lotus-power | head -1`
        fi
        grep -E "seal_sector:|committing sector" ~/log/$logFile
        ;;
  pwd)
       pwd
       ;;
  pinfo)
       pinfo
       ;;
  *)
        echo "Usage: ~/bin/view_lotus.sh {start|mining|slave|poster|wn|wp|restart|restartSlave|mguard|sguard|stopguard|cleanEnv|cleanBin|stopall|stopsalve|log|logm|tailm|logs|logp|logwn|logwd|wallet|info|infos|deal|height|peers|id|prove|proves|seal|pwd|pinfo}" || true
        exit 1
esac
exit 0