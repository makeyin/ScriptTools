#/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
jieguo=`tail /$winnhome/$winnuser/log/$wnlogfile |grep "cannot allocate memory" |wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo $jieguo
fi


###export连错fullnode或钱包地址缺失
#/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
jieguo=`tail /$winnhome/$winnuser/log/$wnlogfile |grep "mine one sep failed: scratching ticket failed: key not found" |wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo $jieguo
fi



##同步自己挖到的块失败
#/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
jieguo=`tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed to submit newly mined block: sync to submitted block failed" |wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo $jieguo
fi







