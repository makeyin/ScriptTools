#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
jieguo=`tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "submit window post" |grep "successfully ExitCode 0" |wc -l`

if [ $jieguo -eq 1 ];then
        echo 0
else
        echo 1
fi
