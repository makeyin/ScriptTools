#/bin/bash
powerhome=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $2}'`
poweruser=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $3}'`
powerlogfile=`ls -lt /$powerhome/$poweruser/log | awk '{print $NF}' | grep lotus | head -1`
jieguo=`tail -20 /$powerhome/$poweruser/log/$powerlogfile |grep "rpc output message buffer "n"" | wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo $jieguo
fi



#/bin/bash
powerhome=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $2}'`
poweruser=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $3}'`
powerlogfile=`ls -lt /$powerhome/$poweruser/log | awk '{print $NF}' | grep lotus | head -1`
jieguo=`tail -20 /$powerhome/$poweruser/log/$powerlogfile |grep "websocket routine exiting" | wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo $jieguo
fi





#/bin/bash
powerhome=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $2}'`
poweruser=`ps -ef |grep '[l]otus-power' | awk -F '/' '{print $3}'`
powerlogfile=`ls -lt /$powerhome/$poweruser/log | awk '{print $NF}' | grep lotus | head -1`
jieguo=`tail -20 /$powerhome/$poweruser/log/$powerlogfile |grep "cannot allocate memory" | wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo $jieguo
fi


