#!/bin/bash
sUser=$USER
PRO_osp_worker='osp-worker daemon' #osp-worker 进程名称"
PRO_osp_provider='osp-provider daemon'  #osp-provider 进程名称"
PRO_osp_window='osp-window daemon'  #osp-provider 进程名称"

Check_User_Name(){
        if [[ ! -n "$sUser" ]];then
                sUser="devnet"
        fi
}
Check_Dir_User(){
        Dir=`ls -l ../|sed -n '2p' |awk -F " " '{print $3}'`
        if [ "$Dir" == "root" ]; then
                echo "User correct"
        else
                exit 2
        fi
}
Check_osp_provider_Status(){
        osp_provider_NUM=`ps -u $sUser -f | grep -w "${PRO_osp_provider}" | grep -v grep |wc -l`
       ## osp_provider_Status=`~/bin/osp-provider net id >/dev/null 2>&1&&echo $?||echo 1`
}

Check_osp_worker_Status(){
        osp_worker_NUM=`ps -u $sUser -f | grep -w "${PRO_osp_worker}" | grep -v grep |wc -l`
        ##osp_worker_Status=`~/bin/osp-worker net id >/dev/null 2>&1&&echo $?||echo 1`
}

Check_osp_window_Status(){
        osp_window_NUM=`ps -u $sUser -f | grep -w "${PRO_osp_window}" | grep -v grep |wc -l`
        ##osp_worker_Status=`~/bin/osp-worker net id >/dev/null 2>&1&&echo $?||echo 1`
}

Start_osp_provider(){
    ~/bin/view_lotus.sh op
}

Start_osp_worker(){
    ~/bin/view_lotus.sh ow
}

Start_osp_window(){
    ~/bin/view_lotus.sh wp
}

function provider(){
Check_User_Name
#Check_Dir_User
while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
        Check_osp_provider_Status
        if [[ ("${osp_provider_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR: osp-provider is down !!! Begin to restart osp-provider "
            echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数 osp-provider:$osp_provider_NUM
                Start_osp_provider
                sleep 60
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` "osp-provider is healthy"
                echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数 osp-provider:$osp_provider_NUM
        fi
    sleep 120
done
}

function window(){
Check_User_Name
#Check_Dir_User
while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
        Check_osp_window_Status
        if [[ ("${osp_window_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR: osp-window is down !!! Begin to restart osp-window "
            echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数 osp-window:$osp_window_NUM
                Start_osp_window
                sleep 60
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` "osp-window is healthy"
                echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数 osp-window:$osp_window_NUM
        fi
    sleep 120
done
}


function worker(){
Check_User_Name
#Check_Dir_User
while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
        Check_osp_worker_Status
        if [[ ("${osp_worker_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR: osp-worker is down !!! Begin to restart osp-worker "
            echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数 osp-worker:$osp_worker_NUM
                Start_osp_worker
                sleep 60
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` "osp-worker is healthy"
                echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数 osp-worker:$osp_worker_NUM
        fi
    sleep 120
done
}

function stopWorkerGuard(){
        echo `date +'%Y-%m-%d %H:%M:%S'` "stop ospGuard-worker"
        kill -9 `ps -u $USER -f | grep "ospGuard.sh worker" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopProviderGuard(){
        echo `date +'%Y-%m-%d %H:%M:%S'` "stop ospGuard-provider"
        kill -9 `ps -u $USER -f | grep "ospGuard.sh provider" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

function stopwindowGuard(){
        echo `date +'%Y-%m-%d %H:%M:%S'` "stop ospGuard-window"
        kill -9 `ps -u $USER -f | grep "ospGuard.sh window" | grep -v grep | awk '{print $2}'` 2> /dev/null
}

case "$1" in
provider)
        provider
        ;;
worker)
        worker
        ;;
window)
        window
        ;;
stopWorkerGuard)
        stopWorkerGuard
        ;;
stopProviderGuard)
        stopProviderGuard
        ;;
stopwindowGuard)
        stopwindowGuard
        ;;
*)
esac