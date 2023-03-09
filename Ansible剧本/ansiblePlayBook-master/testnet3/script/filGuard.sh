#!/bin/bash
# Usage: setsid ~/bin/loGuard.sh > ~/log/loGuard.out 2>&1  &
sUser=$USER
PRO_NAME='lotus daemon'  # master full node进程名称"
PRO_Miner_NAME='lotus-storage-miner'  #master miner 进程名称"
PRO_SLAVE_NAME='lotus-slave-miner' #slave lotus-slave-miner 进程名称"
PRO_POSTER_NAME='lotus-poster'  #slave lotus-poster 进程名称"

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
Check_Lotus_Status(){
        Lotus_Pid_NUM=`ps -u $sUser -f | grep -w "${PRO_NAME}" | grep -v grep |wc -l`
        ##Lotus_Cmd_Status=`~/bin/lotus net id >/dev/null 2>&1&&echo $?||echo 1`
}

Check_Lotus_Miner_Status(){
        Lotus_Miner_Pid_NUM=`ps -u $sUser -f | grep -w "${PRO_Miner_NAME}" | grep -v grep |wc -l`
        ##Lotus_Miner_Cmd_Status=`~/bin/lotus-storage-miner net id >/dev/null 2>&1&&echo $?||echo 1`
}

Check_Lotus_Poster_Status(){
        Lotus_Poster_NUM=`ps -u $sUser -f | grep -w "${PRO_POSTER_NAME}" | grep -v grep |wc -l`
        ##Lotus_Poster_Status=`~/bin/lotus-poster net id >/dev/null 2>&1&&echo $?||echo 1`
}

Check_Lotus_Slave_Status(){
        Lotus_Slave_NUM=`ps -u $sUser -f | grep -w "${PRO_SLAVE_NAME}" | grep -v grep |wc -l`
        ##Lotus_Slave_Status=`~/bin/lotus-slave-miner net id >/dev/null 2>&1&&echo $?||echo 1`
}

Start_Miner_Lotus(){
        ~/bin/view_lotus.sh mining
}

Start_Lotus(){
    ~/bin/view_lotus.sh start
}

Restart_Lotus(){
    ~/bin/view_lotus.sh restart
}
Start_Poster_Lotus(){
    ~/bin/view_lotus.sh startPoster
}

Start_Slave_Lotus(){
    ~/bin/view_lotus.sh startSlave
}

Restart_Slave_Lotus(){
    ~/bin/view_lotus.sh restartSlave
}

function master(){
Check_User_Name
#Check_Dir_User
while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
    #检查Lotus状态
    Check_Lotus_Status
    #Check_Lotus_Miner_Status
    #少于1，或者命令执行不成功重启进程
        if [[ ("${Lotus_Pid_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR: lotus daemon is down !!! Begin to restart lotus and lotus-storage-miner"
            echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数           lotus:$Lotus_Pid_NUM  lotus-storage-miner:$Lotus_Miner_Pid_NUM
                Restart_Lotus
                sleep 60
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` " lotus daemon is healthy"
        fi

        Check_Lotus_Miner_Status
        if [[ ("${Lotus_Miner_Pid_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR:  lotus-storage-miner is down !!! Begin to restart lotus-storage-miner"
            echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数           lotus:$Lotus_Pid_NUM  lotus-storage-miner:$Lotus_Miner_Pid_NUM
                Start_Miner_Lotus
                sleep 60
                #Check_Lotus_Miner_Status
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` " lotus-storage-miner is healthy"
                echo `date +'%Y-%m-%d %H:%M:%S'`  当前进程数       lotus:$Lotus_Pid_NUM  lotus-storage-miner:$Lotus_Miner_Pid_NUM
        fi
    sleep 120
done
}

function poster(){
Check_User_Name
#Check_Dir_User
while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
    #检查slave poster状态
        Check_Lotus_Poster_Status
    #少于1，或者命令执行不成功重启进程
        if [[ ("${Lotus_Poster_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR: lotus-poster is down !!! Begin to restart lotus-poster"
            echo -e "\033[41;37m `date +'%Y-%m-%d %H:%M:%S'`  当前进程数           lotus-poster:$Lotus_Poster_NUM \033[0m"
                Start_Poster_Lotus
                sleep 60
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` " lotus-poster is healthy"
                echo -e "\033[44;37m `date +'%Y-%m-%d %H:%M:%S'`  当前进程数           lotus-poster:$Lotus_Poster_NUM \033[0m"
        fi
    sleep 120
done
}

function slave(){
Check_User_Name
#Check_Dir_User
while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
        #检查slave poster状态
        Check_Lotus_Slave_Status
        if [[ ("${Lotus_Slave_NUM}" -lt "1") ]];then
            echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR:  lotus-slave is down !!! Begin to restart lotus-slave"
            echo -e "\033[41;37m `date +'%Y-%m-%d %H:%M:%S'`  当前进程数           lotus-slave:$Lotus_Slave_NUM   \033[0m"
                Start_Slave_Lotus
                sleep 60
        else
                echo `date +'%Y-%m-%d %H:%M:%S'` " lotus-slave is healthy"
                echo -e "\033[44;37m `date +'%Y-%m-%d %H:%M:%S'`  当前进程数           lotus-slave:$Lotus_Slave_NUM \033[0m"
        fi
    sleep 120
done
}

function stop(){
        echo `date +'%Y-%m-%d %H:%M:%S'` "stop filGuard"
        kill -9 `ps -u $USER -f | grep filGuard | grep -v grep | awk '{print $2}'` 2> /dev/null
}
case "$1" in
master)
        master
        ;;
slave)
        slave
        ;;
poster)
        poster
        ;;
stop)
        stop
        ;;
*)
        esac