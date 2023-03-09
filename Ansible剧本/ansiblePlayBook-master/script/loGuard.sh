#!/bin/bash
# Usage: setsid ~/bin/loGuard.sh > ~/log/loGuard.out 2>&1  &

sUser=$USER
PRO_NAME='lotus'  #lotus进程名称"
PRO_Miner_NAME="lotus-storage-miner"  #lotus miner 进程名称"

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
	Lotus_Pid_NUM=`ps -u $sUser -f | grep -w ${PRO_NAME} | grep -v grep |wc -l`
	Lotus_Cmd_Status=`~/bin/lotus net id >/dev/null 2>&1&&echo $?||echo 1`
}
Check_Lotus_Miner_Status(){
	Lotus_Miner_Pid_NUM=`ps -u $sUser -f | grep -w ${PRO_Miner_NAME} | grep -v grep |wc -l`
	Lotus_Miner_Cmd_Status=`~/bin/lotus-storage-miner net id >/dev/null 2>&1&&echo $?||echo 1`
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

Check_User_Name
#Check_Dir_User

while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
    #检查Lotus状态
    Check_Lotus_Status
    #Check_Lotus_Miner_Status
    #少于1，或者命令执行不成功重启进程
	if [[ ("${Lotus_Pid_NUM}" -lt "1") || ("${Lotus_Cmd_Status}" -ne "0") ]];then
	    echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR: lotus daemon is down !!! Begin to restart lotus and lotus-storage-miner"
		Restart_Lotus
		sleep 60
	else
		echo `date +'%Y-%m-%d %H:%M:%S'` " lotus daemon is healthy"
	fi
	
	Check_Lotus_Miner_Status
	if [[ ("${Lotus_Miner_Pid_NUM}" -lt "1") || ("${Lotus_Miner_Cmd_Status}" -ne "0") ]];then
	    echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR:  lotus-storage-miner is down !!! Begin to restart lotus-storage-miner"
		Start_Miner_Lotus
		sleep 60
		#Check_Lotus_Miner_Status
	else
		echo `date +'%Y-%m-%d %H:%M:%S'` " lotus-storage-miner is healthy"
	fi
    sleep 120
done
exit 0
