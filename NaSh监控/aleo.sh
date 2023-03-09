#!/bin/bash
###基础变量定义
#pushGateWayAddress="pushgateway.azurepool.art:9091"
pushGateWayAddress="172.28.105.164:9091"
Gpu_Log_dir="/root/log/damo.log"
Cpu_Log_dir="/root/bin/CPU.log"
minerID="nash"
Mount_dir="/tmp/.hidden/.app"
#ProName="aleo-worker"
ProName="damominer"
function hostInfo(){
hostNameIp=$(ip a | grep 'inet ' | grep global | grep -v '\.0.1/' | awk -F "/" '{print $1}' | awk '{print $2}' | head -1 | sed 's/^[ \t]*//g' | sed 's/\.//g')
cpus=$(cat /proc/cpuinfo | grep processor | wc -l)
cpuName=$(cat /proc/cpuinfo | grep "model name" | uniq | awk -F ":" '{print $2}' | sed 's/^[ \t]*//g')
cpuCode=$(echo $cpuName | awk '{print $3}' | sed 's/^[ \t]*//g')
DingTalkApi='https://oapi.dingtalk.com/robot/send?access_token=c9f065a42fdd1071572a85fe38b2b6db37629e0a0550c19d85bd361a58c13362'
if [[ $cpuCode = "CPU" ]] || [[ $cpuCode = "Gold" ]] || [[ $cpuCode = "Silver" ]] || [[ $cpuCode = "Processor" ]]; then
        cpuCode=$(echo $cpuName | awk '{print $4}' )
fi
if [ $(echo $cpuName | grep "AMD Ryzen" | wc -l) -gt 0 ]; then
        cpuCode=$(echo $cpuName | awk '{print $4}')
        if [ $cpuCode = "PRO" ]; then
                cpuCode=$(echo $cpuName | awk '{print $5}')
        fi
fi
hostInfoPut="$hostNameIp-$cpuCode-$cpus"
}

function pushGateWay(){
        echo "CpuPower $CpuPowerHash" | curl --data-binary @- http://${pushGateWayAddress}/metrics/job/aleo_CPU/minerID/${minerID}/hostInfo/${hostInfoPut}/aleoStatus/${aleoStatus}
}
function GpuPushGateWay(){
        echo "GpuPower $GpuPowerHash" | curl --data-binary @- http://${pushGateWayAddress}/metrics/job/aleo_GPU/minerID/${minerID}/hostInfo/${hostInfoPut}/aleoStatus/${Aleo_GPU_STATUS}
}
#function pushGateWayStop(){
#       echo "CpuPower 0" | curl --data-binary @- http://${pushGateWayAddress}/metrics/job/aleo_CPU/minerID/${minerID}/hostInfo/${hostInfoPut}/aleoStatus/${aleoStatus}
#}
#function GpuPushGateWayStop(){
#       echo "GpuPower 0" | curl --data-binary @- http://${pushGateWayAddress}/metrics/job/aleo_GPU/minerID/${minerID}/hostInfo/${hostInfoPut}/aleoStatus/${Aleo_GPU_STATUS}
#}

function deleteData(){
        curl -X DELETE http://${pushGateWayAddress}/metrics/job/aleo_CPU/minerID/${minerID}/hostInfo/${hostInfoPut}/aleoStatus/${aleoStatus}
}
function GpuDeleteData(){
        curl -X DELETE http://${pushGateWayAddress}/metrics/job/aleo_GPU/minerID/${minerID}/hostInfo/${hostInfoPut}/aleoStatus/${Aleo_GPU_STATUS}
}
function aleoStatusGet(){
        ListenPort1=`ss -anpt |grep LISTEN | grep 4133 | grep -v grep | wc -l`
        ListenPort2=`ss -anpt |grep LISTEN | grep 4140 | grep -v grep | wc -l`
        if [ -n "${ListenPort1}" ];then
                ProName=`ss -anpt |grep LISTEN |grep 4133 | awk '{print $NF}' | awk -F\" '{print $2}'`
                PidStatus=`ps -ef |grep "${ProName}"  | grep -v grep | awk '{print $2}'`
        elif [ -n "${ListenPort2}" ];then
                ProName=`ss -anpt |grep LISTEN |grep 4140 | awk '{print $NF}' | awk -F\" '{print $2}'`
                PidStatus=`ps -ef |grep "${ProName}" | grep -v grep | awk '{print $2}'`
        else
                PidStatus=""
        fi
}
function Time(){
        Hours=`date -d "8 hours ago" +"%H"`
        Log_Time_start=`date -d "2 minute ago" +"%Y-%m-%dT${Hours}:%M"`
        Log_Time_end=`date -d "1 minute ago" +"%Y-%m-%dT${Hours}:%M"`
        Log_Time_sys=`TZ=Asia/Shanghai date +"%Y-%m-%dT%H:%M:%S"`

}
function DingTalkFailed(){
Time
curl "$DingTalkApi"  \
   -H 'Content-Type: application/json'  \
   -d '{
     "msgtype": "markdown", 
     "markdown": { 
         "title":"aleo状态异常:stop",
         "text": "对应IP:'$hostInfoPut',当前状态:'stop',当前时间:'$Log_Time_sys'" 
     } 
}'
}
function CpuPower(){
        aleoStatusGet
        if [ "${ListenPort2}" != "0" ] && [  -n "${PidStatus}" ];then
                CpuPowerHash=`tail -n100 $Cpu_Log_dir | grep "Total solutions" | awk -F\( '{print $2}' | awk '{print $2}' | tail -1`
                if [ "${PowerHash}" == "---" ];then
                        CpuPowerHash=0
                elif [ x"${PowerHash}" == x"" ];then
                        CpuPowerHash=0
                fi
                aleoStatus="stop"
                deleteData
                sleep 3s
                aleoStatus="start"
                pushGateWay
        elif [ "${ListenPort1}" != "0" ] && [  -n "${PidStatus}" ];then
                Time
                PowerTotal=`sed -n /$Log_Time_start/,/$Log_Time_end/p $Cpu_Log_dir |grep 'CoinbasePuzzle' | wc -l`
                if [ "$PowerTotal" != "0" ];then
                        CpuPowerHash=`expr ${PowerTotal} / 60`
                else
                        CpuPowerHash="0"
                fi
                aleoStatus="stop"
                deleteData
                sleep 3s
                aleoStatus="start"
                pushGateWay
        else
                CpuPowerHash="0"
                aleoStatus="start"
                deleteData
                sleep 3s
                aleoStatus="stop"
                pushGateWay
        fi
}
function aleoGpuStatusGet(){
        GPU_PID=`ps -ef |grep ${ProName} | grep -v grep | awk '{print $2}'`
        logStat=$(date -d "`stat $Gpu_Log_dir|grep Change: | awk '{print $3}'`" +%s)
        localStat=`date +"%s"`
        exprTime=`expr $localStat - $logStat`
        nvidia-smi -L >/dev/null
        if [ $? -eq 0 ] && [ -n "${GPU_PID}" ] && [ $exprTime -le 120 ];then
                Aleo_GPU_STATUS="start"
        else
                Aleo_GPU_STATUS="stop"
        fi
}
function GpuPower(){
        aleoGpuStatusGet
        if [ "${Aleo_GPU_STATUS}" == "start" ];then
                GpuPowerHash=`tail -n100 $Gpu_Log_dir | grep ToTal |awk '{print $4}' | awk -F'|' '{print $1}' | tail -1`
                GpuPushGateWay
                Aleo_GPU_STATUS="stop"
                GpuDeleteData
        else
                GpuPowerHash=0
                GpuPushGateWay
                Aleo_GPU_STATUS="start"
                GpuDeleteData
                DingTalkFailed
        fi

}


function startMonitor(){
                hostInfo
                while true;do
                #CpuPower
                GpuPower
                sleep 15s
                done
}
startMonitor
