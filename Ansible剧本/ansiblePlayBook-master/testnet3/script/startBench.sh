#!/bin/bash
function stop(){
    echo `date +'%Y-%m-%d %H:%M:%S'` "Kill old bench process..."
    kill -9 `ps -u $USER -f | grep bench | grep -v grep | awk '{print $2}'` 2> /dev/null
    sleep 15
}

function setOspParam(){
  GpuNumber=`lspci | grep -i vga | grep -i nvidia|wc -l`

  if [[ ${GpuNumber} > 0 ]];then
      export OPTION4=true
      export OPTION5=true
      export OPTION6=${GpuNumber}
      export OPTION3=9
  else
      export OPTION4=false
      export OPTION5=false
      export OPTION6=0
      export OPTION3=5
  fi

  ###下面为通用的参数
  export RUST_BACKTRACE=full
  export RUST_LOG=info
  export OPTION1=false
  export OPTION7=9500
  export OPTION8=false
  export OPTION9=0
  export OPTION10=0
  export OPTION11=false
  export OPTION14=0
  export OPTION15=0
  export OPTION17=32
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
    if [ -n "`ps aux | grep bench | grep -v grep`" ]
    then
        echo `date +'%Y-%m-%d %H:%M:%S'` "Kill old bench process..."
        kill -9 `ps -u $USER -f | grep bench | grep -v grep | awk '{print $2}'` 2> /dev/null
        sleep 15
    fi

   
    echo `date +'%Y-%m-%d %H:%M:%S'` "Begin to start bench process..."
    setOspParam
    setsid ./bench > ./bench.`date +"%m%d%H%M"`.out 2>&1 &
    echo `date +'%Y-%m-%d %H:%M:%S'` "Bench Started!"
}

case "$1" in
  start|"")
        start
        ;;
  stop)
        stop
        ;;
  log)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt| awk '{print $NF}' | grep super_seal | grep out | head -1`
        fi
        echo "######################### Analyze log file name is: "$logFile
        grep -E "Start seal thread pool|layer: .*, cost time|Precommit phase .* takes|Commit phase .* takes|Seal commit .* sectors"  $logFile
        ;;
  avg)
        logFile=$2
        if [ ! -n "$logFile" ];then
                logFile=`ls -lt| awk '{print $NF}' | grep super_seal | grep out | head -1`
        fi
        echo "######################### Analyze log file name is: "$logFile
        echo "Precommit phase 1 takes time: " `grep -E "Precommit phase 1 takes" --text $logFile | awk '{print $NF}' | awk -F '.' '{a+=$1}END{print a/NR}'`"s"
        echo "Precommit phase 2 takes time: " `grep -E "Precommit phase 2 takes" --text $logFile | awk '{print $NF}' | awk -F '.' '{a+=$1}END{print a/NR}'`"s"
        echo "Commit phase 1 takes time: " `grep -E "Commit phase 1 takes" --text $logFile | awk '{print $NF}' | awk -F '.' '{a+=$1}END{print a/NR}'`"ms"
        echo "Commit phase 2 takes time: " `grep -E "Commit phase 2 takes" --text $logFile | awk '{print $NF}' | awk -F '.' '{a+=$1}END{print a/NR}'`"s"
        ;;
  *)
        echo "Usage: ~/bin/startBench.sh {start|stop|log}" || true
        exit 1
esac
exit 0