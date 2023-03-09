#!/bin/bash
# Usage: setsid ~/bin/slaveGuard.sh > ~/log/slaveGuard.out 2>&1  &

sUser=$USER
PRO_NAME='lotus'  #lotus进程名称"
PRO_Miner_NAME="lotus-storage-miner"  #lotus miner 进程名称"
Check_User_Name(){
	if [[ ! -n "$sUser" ]];then
		sUser="devnet"
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
Check_Lotus_Slave_Status(){
	Lotus_Slave_Pid_NUM=`ps -u $sUser -f | grep -w ${PRO_Miner_NAME} | grep -v grep |wc -l`
	Lotus_Slave_Cmd_Status=`~/bin/lotus-slave-miner net id >/dev/null 2>&1&&echo $?||echo 1`
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

Restart_Slave()){
    ~/bin/view_lotus.sh slave
}

Check_User_Name
#Check_Dir_User

while true ; do
    echo `date +'%Y-%m-%d %H:%M:%S'` "  ============ Begin to check health status ============ "
    #检查Lotus状态
    Check_Lotus_Slave_Status

	if [[ ("${Lotus_Slave_Pid_NUM}" -lt "1") || ("${Lotus_Slave_Cmd_Status}" -ne "0") ]];then
	    echo `date +'%Y-%m-%d %H:%M:%S'` " ERROR:  lotus-slave-miner is down !!! Begin to restart lotus-slave-miner"
		Restart_Slave
		sleep 60
	else
		echo `date +'%Y-%m-%d %H:%M:%S'` " lotus-slave-miner is healthy"
	fi
    sleep 120
done
exit 0
