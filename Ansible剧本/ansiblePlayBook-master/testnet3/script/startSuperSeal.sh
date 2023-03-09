#!/bin/bash
function stop(){
    echo `date +'%Y-%m-%d %H:%M:%S'` "Kill old super_seal process..."
    kill -9 `ps -u $USER -f | grep super_seal | grep -v grep | awk '{print $2}'` 2> /dev/null
    sleep 15
}

function start(){
    if [ -n "`ps aux | grep super_seal | grep -v grep`" ]
    then
        echo `date +'%Y-%m-%d %H:%M:%S'` "Kill old super_seal process..."
        kill -9 `ps -u $USER -f | grep super_seal | grep -v grep | awk '{print $2}'` 2> /dev/null
        sleep 15
    fi
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
    
    export RUST_BACKTRACE=full
    export RUST_LOG=info
    export OPTION9=1     #hash first,如设置值不为0的情况下,将判断如果有hash GPU任务（CS和默克树）,且排队hash GPU超过设置值,则零知识证明会放弃抢占GPU
    export OPTION10=10    #OPT_CPU,如果设置为0,则是不允许GPU的活给CPU干

    ################需要修改的参数###################################################################
    export TOTAL_TASKS=30
    export PRECOMMIT_PHASE1_COUNT=16     #vde的线程数,需要等于 OPTION14 + OPTION17
    export PRECOMMIT_PHASE2_COUNT=1
    export COMMIT_COUNT=1
    export DO_BELLMAN=false              #默认不做commit2,如果要做则打开
    export OPTION7=10000                  #设置为符合GPU的内存大小
    export OPTION14=0                    #跑VDE优化版本的数量,Disk版本,增加一个增加40G内存
    export OPTION17=0                    #跑官方VDE版本的数量,增加一个增加64G内存
    export OPTION18=None                 #nvme的路径,默认有nvme的话路径是/tank3/vde,没有nvme的话填写None
    export OPTION20=true                 #开启vde cache优化, default is true
    ################################################################################################

    echo `date +'%Y-%m-%d %H:%M:%S'` "Begin to start super_seal process..."
    setsid ./super_seal > ./super_seal.`date +"%m%d%H%M"`.out 2>&1 &
    echo `date +'%Y-%m-%d %H:%M:%S'` "Super Seal Started!"
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
        echo "Usage: ~/bin/startSuperSeal.sh {start|stop|log}" || true
        exit 1
esac
exit 0