#!/bin/bash
#本脚本作者对执行后的一切后果不负责！请慎重执行！

#取进程路径--------GO
homeuser=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $8}' |head -n1`
user=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $9}' |head -n1`
#--------END

#判断是否为root执行--------GO
yh=`whoami |grep root |wc -l`
if [ $yh -ne 1 ];then
	echo -e "\033[41;37m                   请使用root执行                        \033[0m"
	exit 1
fi
#--------END


#判断agent是否存在与安装--------GO
dpkg -s zabbix-agent >/dev/null 2>&1
if [ $? -ne 0 ];then
		echo -e "\033[42;37m检测出未安装zabbix-agent，正在安装请等待。。。。 \033[0m"
		wget http://repo.zabbix.com/zabbix/5.0/ubuntu/pool/main/z/zabbix-release/zabbix-release_5.0-1%2Bbionic_all.deb
		dpkg -i zabbix-release_5.0-1+bionic_all.deb
		apt-get update
		apt-get  install zabbix-agent -y >/dev/null 2>&1
		echo -e "\033[42;37m zabbix-agent安装完成\033[0m"
		sleep 1
#判断参数是否添加
	if [ ! -n "$1" ] ;then
		echo "可能是之前未安装过agent，需要配置-配置文件，按提示操作。"
		echo "请在执行脚本后加上被监控机编号参数：节点号-机器IP后2段（t014XXX-xx.xx）"
		exit 1
	fi

	if [ ! -n "$2" ] ;then
		echo "请在执行脚本后加上监控机IP地址参数-千岛湖为（10.10.7.1），客户除外"
		exit 1
	fi

cat >/etc/zabbix/zabbix_agentd.conf<<EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$2
ServerActive=$2
Hostname=$1
StartAgents=0
Timeout=30
Include=/etc/zabbix/zabbix_agentd.d/*.conf
UnsafeUserParameters=1
EOF
mkdir -p  /etc/zabbix/zabbix_agentd.d
mkdir -p /var/log/zabbix/
touch /var/log/zabbix/zabbix_agentd.log
chown  zabbix.zabbix /var/log/zabbix/zabbix_agentd.log
chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d
chown -R zabbix.zabbix /var/log/zabbix
systemctl restart zabbix-agent >/dev/null 2>&1
if [ $? -eq 0 ];then
	echo -e "\033[42;37m agent配置完成,启动成功 \033[0m"
else
	echo -e "\033[41;37m agent配置失败,启动失败 \033[0m"
	echo -e "\033[41;37m 退出... \033[0m"
	sleep 3
	exit
fi
else
if [ -n "$2" ];then
cat >/etc/zabbix/zabbix_agentd.conf<<EOF
PidFile=/var/run/zabbix/zabbix_agentd.pid
LogFile=/var/log/zabbix/zabbix_agentd.log
LogFileSize=0
Server=$2
ServerActive=$2
Hostname=$1
StartAgents=0
Timeout=30
Include=/etc/zabbix/zabbix_agentd.d/*.conf
UnsafeUserParameters=1
EOF
mkdir -p  /etc/zabbix/zabbix_agentd.d
mkdir -p /var/log/zabbix/
touch /var/log/zabbix/zabbix_agentd.log
chown  zabbix.zabbix /var/log/zabbix/zabbix_agentd.log
chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d
chown -R zabbix.zabbix /var/log/zabbix
systemctl restart zabbix-agent >/dev/null 2>&1
fi
agenthostename=`ls /etc/zabbix/zabbix_agentd.conf >/dev/null 2>&1 && echo 'Hostname为' $(cat /etc/zabbix/zabbix_agentd.conf |awk -F '=' '/Hostname/{print $2}')`
echo -e "\033[42;37m agent已存在无需安装，配置文件中 $agenthostename \033[0m"
fi
#--------END

#===================================================以上是部署agent脚本===================================================#

#判断是否有/script目录--------GO
if [ ! -d /script/jkxx ];then
mkdir -p /script/jkxx
fi
#--------END

#===================================================↓lotus↓===================================================#
sleep 3
lts=`ps -ef |grep 'lotus daem[on]' |wc -l`
if [ $lts -ge 1 ];then

#lotus进程监控--------GO
cat >/script/lotus-course.sh<<'EOF'
#!/bin/bash

ps -ef |grep '[l]otus daemon'|wc -l
EOF
#--------END

#lotus启动时间监控--------GO
cat >/script/lotus-uptime.sh<<'EOF'
#!/bin/bash

ps -p `ps -ef|grep 'lotus dae[mon]' |awk '{print $2}'` -o etime |awk 'NR==2{print $1}'|grep '-' >/dev/null 2>&1
if [ $? -ne 0 ];then
#        date -d "$(ps -p `ps -ef|grep 'lotus dae[mon]' |awk '{print $2}'` -o etime |awk 'NR==2{print $1}')" +"%H时%M分%S秒"
echo '0'
else
        ps -p `ps -ef|grep 'lotus dae[mon]' |awk '{print $2}'` -o etime |awk 'NR==2{print $1}'|awk -F '-' '{print $1}'
fi
EOF
#--------END

#日志监控--------GO
cat >/script/msg_unpacked.sh<<'EOF'
#!/bin/bash

lotushome=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $2}'`
lotususer=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $3}'`
lotuslog=`ls /$lotushome/$lotususer/log|grep 'lotus\.' |tail  -n1`
tail -50 /$lotushome/$lotususer/log/$lotuslog|grep "including pending messages" |wc -l
EOF
#--------END

#日志监控--------GO
cat >/script/msg_failed.sh<<'EOF'
#!/bin/bash

lotushome=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $2}'`
lotususer=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $3}'`
lotuslog=`ls /$lotushome/$lotususer/log|grep 'lotus\.' |tail  -n1`
tail -50 /$lotushome/$lotususer/log/$lotuslog|grep "failed to fetch all bls messages for block received over pubusb" |wc -l
EOF
#--------END

#日志监控--------GO
cat >/script/pendingTooklow.sh<<'EOF'
#!/bin/bash

lotushome=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $2}'`
lotususer=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $3}'`
lotuslog=`ls /$lotushome/$lotususer/log|grep 'lotus\.' |tail  -n1`
pendingtooktime=`tail -50  /$lotushome/$lotususer/log/$lotuslog|grep "pendingTook" |awk -F '[ ".]+' '{print $15}'|tail -n1`

if [ -n $pendingtooktime ];then
        echo 0
        exit
        #正常
fi

if [ $pendingtooktime -ge 10 ];then
        echo 1
        #大于10秒
else
        echo 0
fi
EOF
#--------END

#日志监控--------GO
cat >/script/future-block.sh<<'EOF'
#!/bin/bash

lotushome=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $2}'`
lotususer=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $3}'`
lotuslog=`ls /$lotushome/$lotususer/log|grep 'lotus\.' |tail  -n1`
tail -50 /$lotushome/$lotususer/log/$lotuslog|grep "block was from the future" |wc -l
EOF
#--------END

#日志监控--------GO
cat >/script/not-enough-funds.sh<<'EOF'
#!/bin/bash

lotushome=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $2}'`
lotususer=`ps -ef|grep 'lotus daem[on]'  |awk -F '/' '{print $3}'`
lotuslog=`ls /$lotushome/$lotususer/log|grep 'lotus\.' |tail  -n1`
tail -50 /$lotushome/$lotususer/log/$lotuslog|grep "not enough funds" |wc -l
EOF
#--------END

#日志监控--------GO
cat >/script/cannot.sh<<'EOF'
lotushome=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $2}'`
lotususer=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $3}'`
logfile=`ls -lt /$lotushome/$lotususer/log | awk '{print $NF}' | grep lotus | head -1`
tail -20 /$lotushome/$lotususer/log/$logfile |grep "cannot allocate memory" | wc -l
EOF
#--------END

#消息池监控--------GO
cat >/script/xxdl.sh<<'EOF'
#!/bin/bash

homeuser=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
userfull=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $9}' |head -n1`

#$1=lotus在什么用户下
#$2=cur6/futrue8
sudo runuser -l $userfull -c '/'$homeuser'/'$userfull'/bin/lotus mpool stat --local'|awk -F '[, ;]+' '/total/{print $'$2'}'
EOF
#--------END

#区块延迟监控--------GO
cat >/script/qukuaiyc.sh<<'EOF'
#!/bin/bash

homeuser=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
userfull=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $9}' |head -n1`

qk=`sudo runuser -l $userfull -c '/'$homeuser'/'$userfull'/bin/lotus chain head | head -1 | xargs -L1 ~/bin/lotus chain getblock | grep Timestamp'|awk -F'[ :,]+' '{print $3}'`
bd=`date +%s`
sj=`expr $bd - $qk`
echo $sj
EOF
#--------END

#监控项--------GO
cat >/script/ApplyBlock.sh<<'EOF'
lotushome=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $2}'`
lotususer=`ps -ef |grep '[l]otus daemon' | awk -F '/' '{print $3}'`
logfile=`ls -lt /$lotushome/$lotususer/log | awk '{print $NF}' | grep lotus | head -1`
grep "ApplyBlock" /$lotushome/$lotususer/log/$logfile |  tail -1000 | awk -F'["]' '{print $22}' | awk -F's' '{x+=$1} END{print x/NR}'
EOF
#--------END

#------------------scripts or conf------------------#

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/msg_unpacked.conf<<'EOF'
UserParameter=zabbix.lotus.no.unpacked,sudo sh /script/msg_unpacked.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/msg_failed.conf<<'EOF'
UserParameter=zabbix.lotus.msg.failed,sudo sh /script/msg_failed.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/pendingTooklow.conf<<'EOF'
UserParameter=zabbix.lotus.pdT.10,sudo sh /script/pendingTooklow.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/future-block.conf<<'EOF'
UserParameter=zabbix.lotus.block.future,sudo sh /script/future-block.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/not-enough-funds.conf<<'EOF'
UserParameter=zabbix.lotus.not.enough,sudo sh /script/not-enough-funds.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/cannot.conf<<'EOF'
UserParameter=zabbix.lotus.cannot.memory,sudo sh /script/cannot.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/lotus-uptime.conf<<'EOF'
UserParameter=lotusuptime,bash /script/lotus-uptime.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/xxdl.conf<<EOF
UserParameter=curxx,sudo bash /script/xxdl.sh $user 6
UserParameter=futxx,sudo bash /script/xxdl.sh $user 8
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/lotus-course.conf<<'EOF'
UserParameter=lotus,bash /script/lotus-course.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/block-lag-time.conf<<'EOF'
UserParameter=blt,bash /script/qukuaiyc.sh
EOF
#--------END

#配置文件--------GO
echo 'UserParameter=ApplyBlock,sudo sh /script/ApplyBlock.sh' >/etc/zabbix/zabbix_agentd.d/ApplyBlock.conf
#--------END

fi
#===================================================↓power↓===================================================#
sleep 3
pwr=`ps -ef |grep 'lotus-power r[un]' |wc -l`
if [ $pwr -ge 1 ];then
#状态监控--------GO
cat >/script/commtype.sh<<'EOF'
#!/bin/bash

shu=`curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#"|grep -v " 0" |grep $1 |awk '{print $2}'`
dyou=`curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#"|grep -v " 0" |grep $1 |awk '{print $2}' |wc -l`
if [ $dyou -eq 0 ];then
        echo 0
else
        echo $shu
fi
EOF
#--------END

#监控项--------GO
cat >/script/powerconf.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |head -n1`
cat /$userjia/$user/.lotusminer/config.toml |grep $1 |grep -v '#'|awk -F '[= ]+' '{print $3}'
EOF
#--------END

#监控项--------GO
cat >/script/committingnew.sh<<'EOF'
#!bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |head -n1`
token=`cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#' |awk -F '"' '{print $2}'`
export FULLNODE_API_INFO=$token
echo ' ' >/script/jkxx/Committing.log
sleep 120
~/bin/lotus-power sectors check --after-hours 4 --states Committing >/script/jkxx/Committing.log
EOF
#--------END

#监控项--------GO
cat >/script/Available-balance.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r  |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |sort -n |head -n1`
token=`sudo cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
sudo runuser -l $user -c 'export FULLNODE_API_INFO='$token' && /'$userjia'/'$user'/bin/lotus-power  info '|awk -F "[ .]+" '/Available/{print $3}'|grep -Ev '#|^$'|sed -n 1P
EOF
#--------END

#监控项--------GO
cat >/script/post-balance.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |sort -n |head -n1`
token=`sudo cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
good=`sudo runuser -l $user -c 'export FULLNODE_API_INFO='$token' && /'$userjia'/'$user'/bin/lotus-power actor control list --verbose '|awk -F '[F.]' '{print $1}'|awk  '/control-'$1'/{print $NF}'`
echo $good >/tmp/post$1.log
sleep 3
cat -A /tmp/post$1.log |awk -F "[m$]" '{print $2}' >/tmp/post$1.txt
ls -l /tmp/post$1.log|grep 'rwx' >/dev/null 2>&1
if [ $? -ne 0 ];then
        chmod 777 /tmp/post$1*
fi
EOF
#--------END

#监控项--------GO
cat >/script/rpc_output.sh<<'EOF'
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
EOF
#--------END

#监控项--------GO
cat >/script/websocket.sh<<'EOF'
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
EOF
#--------END

#监控项--------GO
cat >/script/cannot.sh<<'EOF'
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
EOF
#--------END

#监控项--------GO
cat >/script/work-balance.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}'|sort -n  |head -n1`
token=`sudo cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
sudo runuser -l $user -c 'export FULLNODE_API_INFO='$token' && /'$userjia'/'$user'/bin/lotus-power info'|awk -F "[ .]+" '/Worker/{print $3}'|grep -Ev '#|^$'
EOF
#--------END

#监控项--------GO
cat >/script/lotus-miner-course.sh<<'EOF'
#!/bin/bash

ps -ef|grep '[l]otus-power run'|wc -l
EOF
#--------END

#监控项--------GO
cat >/script/rpcpower.sh<<'EOF'
#!/bin/bash
powerhome=`ps -ef|grep 'lotus-power r[un]' |awk -F '/' '/run/{print $2}'`
poweruser=`ps -ef|grep 'lotus-power r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$powerhome/$poweruser/log | awk '{print $NF}' | grep lotus-power | head -1`
tail /$powerhome/$poweruser/log/$wnlogfile |grep "websocket connection closed" |wc -l
EOF
#--------END

#------------------scripts or conf------------------#

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/powerconf.conf<<'EOF'
UserParameter=EMPCOC,sudo bash /script/powerconf.sh EnableManualPreCommitOnChain
UserParameter=MSTOL,sudo bash /script/powerconf.sh MaxSealTotal
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/logpower.conf<<'EOF'
UserParameter=zabbix.power.cannt,sudo sh /script/cannot.sh
UserParameter=zabbix.power.websocket,sudo sh /script/websocket.sh
UserParameter=zabbix.power.rpc.output,sudo sh /script/rpc_output.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/Available-balance.conf<<"EOF"
UserParameter=available,sudo bash /script/Available-balance.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/lotus-miner-course.conf<<"EOF"
UserParameter=lotus-miner,bash /script/lotus-miner-course.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/post-balance.conf<<"EOF"
UserParameter=post0.balance,bash /script/post-balance.sh 0 && sudo cat /tmp/post0.txt
UserParameter=post1.balance,bash /script/post-balance.sh 1 && sudo cat /tmp/post1.txt
UserParameter=post2.balance,bash /script/post-balance.sh 2 && sudo cat /tmp/post2.txt
UserParameter=post3.balance,bash /script/post-balance.sh 3 && sudo cat /tmp/post3.txt
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/work-balance.conf<<"EOF"
UserParameter=worker,bash /script/work-balance.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/commtting.conf<<'EOF'
UserParameter=cmt4xx,expr `cat /script/jkxx/Committing.log |awk -F '[>:]' '/即将过期/{print $2}' |wc -l` / 2
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/commtype.conf<<'EOF'
UserParameter=cmtfld,sudo bash /script/commtype.sh SectorStateCommitFailed
UserParameter=cmting,sudo bash /script/commtype.sh SectorStateCommitting
UserParameter=pcmting,sudo bash /script/commtype.sh SectorStatePreCommitting
UserParameter=psld,sudo bash /script/commtype.sh SectorStatePreSealed
UserParameter=sbct,sudo bash /script/commtype.sh SectorStateSubmitCommit
UserParameter=precmtwt,sudo bash /script/commtype.sh SectorStatePreCommitWait
UserParameter=cmtwt,bash /script/commtype.sh SectorStateCommitWait
EOF
#--------END

#配置文件--------GO
echo 'UserParameter=rpcpower,sudo sh /script/rpcpower.sh' >/etc/zabbix/zabbix_agentd.d/rpcpower.conf
#--------END

#------------------system------------------#
grep 'committingnew' /var/spool/cron/crontabs/$user >/dev/null 2>&1 
if [ $? -ne 0 ];then
cat >>/var/spool/cron/crontabs/$user<<'EOF'
#Committing4小时过期检查脚本
0 23 * * * bash /script/committingnew.sh &
0 1 * * * bash /script/committingnew.sh &
0 3 * * * bash /script/committingnew.sh &
0 5 * * * bash /script/committingnew.sh &
0 7 * * * bash /script/committingnew.sh &
0 9 * * * bash /script/committingnew.sh &
0 11 * * * bash /script/committingnew.sh &
0 13 * * * bash /script/committingnew.sh &
0 15 * * * bash /script/committingnew.sh &
0 17 * * * bash /script/committingnew.sh &
0 19 * * * bash /script/committingnew.sh &
0 21 * * * bash /script/committingnew.sh &
EOF
fi
chown $user.crontab /var/spool/cron/crontabs/$user
touch /script/jkxx/Committing.log
ln -s /script/jkxx/Committing.log /$homeuser/$user/overtime_commtting.log >/dev/null 2>&1
fi
#===================================================↓window↓===================================================#
sleep 3
userwin=`ps -ef |grep /bin/lotus-win[dow] |awk -F '[ /]+' '{print $9}' |head -n1`
widw=`ps -ef|grep 'lotus-window r[un]' |wc -l`
if [ $widw -ge 1 ];then

#监控项--------GO
cat >/script/peerid.sh<<'EOF'
#!/bin/bash

homeuser=`ps -ef |grep '/bin/lotus-win[dow]' |awk -F '[ /]+' '{print $8}' |head -n1`
user=`ps -ef |grep /bin/lotus-win[dow] |awk -F '[ /]+' '{print $9}' |head -n1`
lie=`cat /$homeuser/$user/poster_peers.list |awk '{print $2}'`
runuser -l $user -c '~/bin/lotus-window net peers '| awk -F ',' '{print $1}' >/tmp/peerid.txt
echo  "\033[41;37m                   ERROR: lotus-window lost poster:(underneath)                        \033[0m" >>/$homeuser/$user/peerid.log
for i in $lie
do
grep  $i /tmp/peerid.txt >/dev/null 2>&1
if [ $? -ne 0 ];then
echo '失去'
echo $i
echo "Problem discovery time: `date +%Y-%m-%d/%T`" >>/$homeuser/$user/peerid.log
echo "The peerID of the problem machine: $i" >>/$homeuser/$user/peerid.log
echo "The IP of the problem machine: `grep $i /$homeuser/$user/poster_peers.list |awk '{print $1}'`" >>/$homeuser/$user/peerid.log
echo '-------------------------------------------------------' >>/$homeuser/$user/peerid.log
fi
done
echo  "\033[42;37m                              The end of the round!!!                                  \033[0m" >>/$homeuser/$user/peerid.log
echo  "\n" >>/$homeuser/$user/peerid.log
tail -n5 /$homeuser/$user/peerid.log|grep 'problem' >/dev/null 2>&1
if [ $? -ne 0 ];then
        A=$(sed -n '$=' /$homeuser/$user/peerid.log)
        sed -i $(($A-4+1)),${A}d /$homeuser/$user/peerid.log
fi
EOF
#--------END

#监控项--------GO
cat >/script/window-process.sh<<'EOF'
#!/bin/bash

ps -ef|grep lotus-wind[ow]|wc -l
EOF
#--------END

#监控项--------GO
cat >/script/window-card.sh<<'EOF'
#!/bin/bash


GPUsum=`nvidia-smi -L | grep "GeForce RTX"| awk   '{print $3,$4}' |wc -l`
oldsum=`cat /script/jkxx/GPUsum.log |tail -n1 |awk '{print $(NF-1)}'`
if [ $GPUsum -eq $oldsum ];then
        echo 0
else
        echo 1
        echo "`date` --- $GPUsum GPUs" >>/script/jkxx/GPUsum.log
fi
EOF
#--------END

#监控项--------GO
cat >/script/faults.sh<<'EOF'
#!/bin/bash

windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`

variate=`cat /$windowhome/$windowuser/.lotuswindow/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
#variate=`awk -F '[= ]+' '/FullNodeToken/{print $3}'  /$windowhome/$windowuser/.lotuswindow/config.toml`

faults=`runuser -l $windowuser -c "export FULLNODE_API_INFO=$variate && /$windowhome/$windowuser/bin/lotus-window proving deadlines "|awk '{sum += $6};END {print sum}'`
recoveries=`runuser -l $windowuser -c "export FULLNODE_API_INFO=$variate && /$windowhome/$windowuser/bin/lotus-window proving deadlines "|awk '{sum += $7};END {print sum}'`
faultnew=`expr $faults - $recoveries`

if [ ! -f /script/jkxx/fault.txt ];then
        echo 0 >/script/jkxx/fault.txt
        sudo chmod 777 /script/jkxx/fault.txt
fi

faultold=`cat /script/jkxx/fault.txt`
if [ $faultnew -ne $faultold ];then
        echo $faultnew >/script/jkxx/fault.txt
        echo 0
        exit
else
        echo $faultnew
fi
EOF
#--------END

#监控项--------GO
cat >/script/rpc_DialArgs.sh<<'EOF'
#/bin/bash
#1. 日志: DialArgs
#解释：与fullnode的网络连接断开了,需要检查fullnode相应lotus运行情况
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "DialArgs" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/rpc_token_cannotbenil.sh<<'EOF'
#/bin/bash
#2. 日志：Full node token info cannot be nil
#解释：配置文件中fullnod info的配置有误，需要检查配置
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "Full node token info cannot be nil" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/rpc_error.sh<<'EOF'
#/bin/bash
#3. 日志：NewFullNodeRPC error
#解释：无法建立,rpc连接,需要重启fullnode
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "NewFullNodeRPC error" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/rpc_ChainNotify_error.sh<<'EOF'
#/bin/bash
#4. 日志：ChainNotify error
#解释：订阅fullnode的chain head变化失败,会自动重试
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "ChainNotify error" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/rpc_channel_closed.sh<<'EOF'
#/bin/bash
#5. 日志：window post scheduler notifs channel closed
#解释：从通知通道获取最新的chain head失败,会自动重试
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "window post scheduler notifs channel closed" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/rpc_broken_pipe.sh<<'EOF'
#/bin/bash
#6. 日志：sending ping message.*write: broken pipe
#解释：这个可以自动重试，不影响window进程；所以降低报警级别，一个小时出现超过40次报警
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -200 /$windowhome/$windowuser/log/$wdlogfile |grep "sending ping message.*write: broken pipe" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/window_compute.sh<<'EOF'
#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -200 /$windowhome/$windowuser/log/$wdlogfile |grep "compute Snark proofs err" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/window_cannot_memory.sh<<'EOF'
#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
jieguo=`tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "cannot allocate memory" |wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo 1
fi
EOF
#--------END

#监控项--------GO
cat >/script/window_post_proof.sh<<'EOF'
#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
jieguo=`tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "Retry this particular zksnark coz it's failed" |wc -l`

if [ $jieguo -eq 0 ];then
        echo 0
else
        echo 1
fi
EOF
#--------END

#监控项--------GO
cat >/script/WindowPost_Not_submitted.sh<<'EOF'
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
EOF
#--------END

#监控项--------GO
cat >/script/window_return_outOfGas.sh<<'EOF'
#/bin/bash
windowhome=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $2}'`
windowuser=`ps -ef|grep 'lotus-window r[un]' |awk -F '/' '/run/{print $3}'`
wdlogfile=`ls -lt /$windowhome/$windowuser/log | awk '{print $NF}' | grep lotus-window | head -1`
tail -50 /$windowhome/$windowuser/log/$wdlogfile |grep "\[wdpost\] Submitting window post"|grep "failed: exit 7" |wc -l
EOF
#--------END

#------------------scripts or conf------------------#

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/rpc_DialArgs.conf<<EOF
UserParameter=rpc-DialArgs,sudo sh /script/rpc_DialArgs.sh
UserParameter=rpc-cannotbenil,sudo sh /script/rpc_token_cannotbenil.sh
UserParameter=rpc-error,sudo sh /script/rpc_error.sh
UserParameter=rpc-Chainerror,sudo sh /script/rpc_ChainNotify_error.sh
UserParameter=rpc-channel-closed,sudo sh /script/rpc_channel_closed.sh
UserParameter=rpc-broken-pipe,sudo sh /script/rpc_broken_pipe.sh
UserParameter=window-compute,sudo sh /script/window_compute.sh
EOF
#--------END

#配置文件--------GO
echo 'UserParameter=faults,sudo bash /script/faults.sh' >/etc/zabbix/zabbix_agentd.d/faults.conf
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/window-card.conf<<'EOF'
UserParameter=windowcard,sudo sh /script/window-card.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/window-process.conf<<'EOF'
UserParameter=windowjc,sudo sh /script/window-process.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/peerid.conf<<'EOF'
UserParameter=peerid,sudo sh /script/peerid.sh |grep '失去' |wc -l
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/rpc.conf<<'EOF'
UserParameter=zabbix.window.post.proof,sudo sh /script/window_post_proof.sh
UserParameter=zabbix.windowpost.not.submitted,sudo sh /script/WindowPost_Not_submitted.sh
UserParameter=zabbix.window.return.outOfGas,sudo sh /script/window_return_outOfGas.sh
UserParameter=zabbix.window.cannot.allocate.memory,sudo sh /script/window_cannot_memory.sh
EOF
#--------END

#------------------system------------------#
sudo bash /script/window-card.sh
ls /$homeuser/$userwin/poster_peers.list >/dev/null 2>&1|| runuser -l $userwin -c '~/bin/lotus-window net peers' |awk -F '[,/ ]+' '{print $4,$1}' >>/$homeuser/$userwin/poster_peers.list
touch /$homeuser/$userwin/peerid.log
chown $userwin.$userwin /$homeuser/$userwin/peerid.log
ls /tmp/peerid.txt >/dev/null 2>&1||touch /tmp/peerid.txt
chmod 777 /tmp/peerid.txt
chown $userwin.$userwin /$homeuser/$userwin/poster_peers.list
fi
#===================================================↓winning↓===================================================#
sleep 3
wing=`ps -ef|grep 'lotus-winning r[un]' |wc -l`
if [ $wing -ge 1 ];then

#监控项--------GO
cat >/script/winning-card.sh<<'EOF'
#!/bin/bash


GPUsum=`nvidia-smi -L | grep "GeForce RTX"| awk   '{print $3,$4}' |wc -l`
oldsum=`cat /script/jkxx/GPUsum.log |tail -n1 |awk '{print $(NF-1)}'`
if [ $GPUsum -eq $oldsum ];then
        echo 0
else
        echo 1
        echo "`date` --- $GPUsum GPUs" >>/script/jkxx/GPUsum.log
fi
EOF
#--------END

#监控项--------GO
cat >/script/meichukuai.sh<<'EOF'
id=`cat /home/devnet/.lotuswinning/config.toml |awk -F '[w"_-]+' '/GroupName/{print $2}'`
newchukuai=`curl -s  https://filfox.info/api/v1/address/$id/blocks\?pageSize\=20\&page\=0 |awk -F ',' '{print $3}' |awk -F ':' '{print $2}'`
qk=`sudo runuser -l devnet -c 'export FULLNODE_API_INFO=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJBbGxvdyI6WyJyZWFkIiwid3JpdGUiLCJzaWduIiwiYWRtaW4iXX0.Vxs3NhIpDn1BUfkFieYJZArFsY782eo8_uJ1eaz06sA:/ip4/10.10.8.187/tcp/1234/http && /home/devnet/bin/lotus chain list' |tail -n1|awk -F ':' '{print $1}'`
echo $newchukuai |grep limit  >/dev/null 2>&1 && cat /script/qukuai.txt|tail -n1 &&  exit
cha=`echo $qk - $newchukuai|bc`
julishangcichukuai=`/usr/bin/expr $cha \* 30 / 60`
if [ $julishangcichukuai -ge 120 ];then
        echo 1
        echo 1 >>/script/qukuai.txt
        #2小时为出块
else
        echo 0
        echo 0 >>/script/qukuai.txt
fi
EOF
#--------END

#监控项--------GO
cat >/script/beacon_error.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed getting beacon entry" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/onesepfailed.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "mine one sep failed: scratching ticket failed: key not found" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/syncblockfailed.sh<<'EOF'
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed to submit newly mined block: sync to submitted block failed" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/winning-process.sh<<'EOF'
#!/bin/bash

ps -ef|grep '/bin/lotus-winni[ng]' |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/cannot_allocate_memory.sh<<'EOF'
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
EOF
#--------END

#监控项--------GO
cat >/script/rpcwn.sh<<'EOF'
#!/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "rpc" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/get_mbi.sh<<'EOF'
#!/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "get mbi info timeout for" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/failed_getting.sh<<'EOF'
#!/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "failed getting beacon entry" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/received.sh<<'EOF'
#!/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "received wtask timeout" |wc -l
EOF
#--------END

#监控项--------GO
cat >/script/send_win_failed.sh<<'EOF'
#!/bin/bash
winnhome=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $2}'`
winnuser=`ps -ef|grep 'lotus-winning r[un]' |awk -F '/' '/run/{print $3}'`
wnlogfile=`ls -lt /$winnhome/$winnuser/log | awk '{print $NF}' | grep lotus-winning | head -1`
tail /$winnhome/$winnuser/log/$wnlogfile |grep "send win failed" |wc -l
EOF
#--------END

#------------------scripts or conf------------------#

#配置文件--------GO
echo 'UserParameter=meichukuai,sudo bash /script/meichukuai.sh' >/etc/zabbix/zabbix_agentd.d/meichukuai.conf
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/sendfailed.conf<<EOF
UserParameter=zabbix.winning.beaconerror,sudo sh /script/beacon_error.sh
UserParameter=zabbix.winning.onesepfailed,sudo sh /script/onesepfailed.sh
UserParameter=zabbix.winning.syncblockfailed,sudo sh /script/syncblockfailed.sh
UserParameter=sendfailed,sudo sh /script/send_win_failed.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/wnlog.conf<<'EOF'
UserParameter=getmbi,sudo sh /script/get_mbi.sh
UserParameter=fgetting,sudo sh /script/failed_getting.sh
UserParameter=received,sudo sh /script/received.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/hostnametest.conf<<'EOF'
UserParameter=jchosts,sudo bash /script/hostnametest.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/winning-process.conf<<'EOF'
UserParameter=winningprocess,sudo sh /script/winning-process.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/canallmem.conf<<'EOF'
UserParameter=zabbix.winning.cannot.memory,sudo sh /script/cannot_allocate_memory.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/rpcwn.conf<<'EOF'
UserParameter=rpcwn,sudo sh /script/rpcwn.sh
EOF
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/winning-card.conf<<'EOF'
UserParameter=winningcard,sudo sh /script/winning-card.sh
EOF
sudo bash /script/winning-card.sh 
#配置文件--------GO
fi
#===================================================↓poster↓===================================================#
sleep 3
pst=`ps -ef|grep 'lotus-poster r[un]' |wc -l`
if [ $pst -ge 1 ];then

#监控项--------GO
cat >/script/poster-jc.sh<<'EOF'
#!/bin/bash

ps -ef |grep lotus-post[er]|wc -l
EOF
#--------END

#------------------scripts or conf------------------#

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/poster-jc.conf<<'EOF'
UserParameter=posterjc,sudo sh /script/poster-jc.sh
EOF
#--------END
fi
#===================================================↓all↓===================================================#
#hoste文件监控添加--------GO
cat  >/script/hostnametest.sh<<'EOF'
#!/bin/bash

hosts=`grep "127.0.0.1 $(hostname)" /etc/hosts |wc -l`
if [ $hosts -eq 0 ];then
echo "127.0.0.1 `hostname`" >>/etc/hosts
echo 1
else
echo 0
fi
EOF
#--------END

#监控项--------GO
cat > /script/bin_version.sh << EOF
#!/bin/bash
txt_file=/script/bin_version.txt
echo "" >  \$txt_file
course_name=\`ps -ef |grep lotus| grep -v grep |grep -v log| grep -v "/bin/bash" |awk -F '/' '{print \$5}'| awk '{print \$1}'\`
course(){
    ps -ef |grep lotus | grep -v grep
}
for i in \$course_name
do
    course_user=\`course | grep \$i | awk '{print \$1}'\`
    course_version=\`sudo runuser -l \$course_user -c "~/bin/\$i -v" | awk '{print \$3}'\`
    echo \$course_version >> \$txt_file
done
for l in \`cat \$txt_file\`
do
        echo \$l
done
EOF
#--------END

#监控项--------GO
cat >/script/tcp_EST.sh<<'EOF'
#!/bin/bash

tclnum=`netstat -na|grep ESTABLISHED|wc -l`
if [ $tclnum -le 1500 ];then
        echo 0
else
        echo 1
fi
EOF
#--------END

#监控项--------GO
cat >/script/time.py<<EOF
import time
import ntplib
import sys
import os


def main():
    try:
        ntp_client = ntplib.NTPClient()
        response = ntp_client.request('ntp.aliyun.com')
        ntp_timeStamp = response.tx_time
        ntp_date = time.strftime('%Y-%m-%d', time.localtime(ntp_timeStamp))
        ntp_time = time.strftime('%X', time.localtime(ntp_timeStamp))
    except:
        print('阿里云ntp服务器坏了，更换其他的NTP服务器试试')
        sys.exit()

    #获取本地服务器时间
    local_timeStamp = time.time()

    #获取阿里云和本机的时间差
    diff = abs(ntp_timeStamp - local_timeStamp)
    print(round(diff,3))

if __name__ == '__main__':
    main()
EOF
#--------END

#监控项--------GO
cat >/script/cpuload.sh<<'EOF'
#!/bin/bash

highload=`cat /proc/cpuinfo|grep processor |wc -l`
newload=$(/usr/bin/uptime |awk -F '[, ]+' '{print $(NF-1)}'|awk -F . '{print $1}')
#newload=$1
averloadNinety=`echo "$highload * 0.9" |bc|awk -F . '{print $1}'`
averloadeighty=`echo "$highload * 0.8" |bc|awk -F . '{print $1}'`

if [ $newload -le $averloadNinety ];then
        if [ $newload -ge $averloadeighty ];then
                echo 1
                #5分钟内平均负载大于最大负载的80%
        else
                echo 0
        fi
else
        if [ $newload -ge $averloadNinety ];then
                #5分钟内平均负载大于最大负载的90%
                echo 2
        fi
fi
EOF
#--------END

#监控项--------GO
cat >/script/freesize.sh<<'EOF'
#!/bin/bash
keyong=`free -m |awk  '/M/{print $NF}'`
zongfree=`free -m |awk  '/M/{print $2}'`
fazhi=`echo "$zongfree * 0.1"|bc|awk -F . '{print $1}'`

if [ $keyong -le $fazhi ];then
        echo 1
else
        echo 0
fi
EOF
#--------END

#监控项--------GO
cat >/script/disk_free.sh<<'EOF'
#!/bin/bash
genfree=`df -h |egrep "/$" |awk '{print $(NF-1)}'|awk -F '%' '{print $1}'`
tank1free=`df -h |egrep "tank1" |awk '{print $(NF-1)}'|awk -F '%' '{print $1}'`

if [ $genfree -ge $1 ];then
        if [ $tank1free -ge $1 ];then
                #根目录和tank1都剩余10%空间
                echo 3
                exit
        fi
fi

if [ $genfree -ge $1 ];then
        #根目录剩余10%空间
        echo 1
        exit
fi

if [ $tank1free -ge $1 ];then
        #tank1目剩余10%空间
        echo 2
        exit
fi

echo '0'
EOF
#--------END

#监控项--------GO
cat >/script/disk_check.sh<<'EOF'
#!/bin/bash

head=`mount |grep tank|wc -l`
echo "disk_check date" >>/script/jkxx/disk_check.txt
if [ $? -ne 0 ];then
        echo 1
        #根盘只读
        exit
fi

if [ $head -eq 0 ];then
        echo 1
        #没找到磁盘tank
        exit
fi

tankro=`mount |grep tank|grep ro|wc -l`
if [ $tankro -ne 0 ];then
        echo 1
else
        echo 0
fi
EOF
#--------END

#------------------scripts or conf------------------#

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/hostnametest.conf<<'EOF'
UserParameter=jchosts,sudo bash /script/hostnametest.sh
EOF
#--------END

#配置文件--------GO
echo "UserParameter=bin.version,bash /script/bin_version.sh" > /etc/zabbix/zabbix_agentd.d/bin_version.conf
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/check_OStime.conf<<EOF 
UserParameter=checktime,sudo python3 /script/time.py
EOF
#--------END

#配置文件--------GO
echo 'UserParameter=ping-3m,echo 0' >/etc/zabbix/zabbix_agentd.d/ping.conf 
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/disk_check.conf<<'EOF'
UserParameter=disk.check,sudo bash /script/disk_check.sh
EOF
#--------END

#配置文件--------GO
echo 'UserParameter=zabbix.system.cpu.load5,sh /script/cpuload.sh' >/etc/zabbix/zabbix_agentd.d/cpuload.conf
#--------END

#配置文件--------GO
echo 'UserParameter=zabbix.system.free.free10,sh /script/freesize.sh' >/etc/zabbix/zabbix_agentd.d/freesize.conf
#--------END

#配置文件--------GO
cat >/etc/zabbix/zabbix_agentd.d/disk_free.conf<<'EOF'
UserParameter=zabbix.system.disk.free10,sudo bash /script/disk_free.sh 90
UserParameter=zabbix.system.disk.free20,sudo bash /script/disk_free.sh 80
UserParameter=zabbix.system.disk.free30,sudo bash /script/disk_free.sh 70
EOF
#--------END

#配置文件--------GO
echo 'UserParameter=zabbix.system.tcp.amount,sh /script/tcp_EST.sh' >/etc/zabbix/zabbix_agentd.d/tcp_EST.conf
#--------END

#------------------system------------------#
pip3 install ntplib
touch /script/jkxx/disk_check.txt
chmod -R 777 /script/
chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d
ls /etc/passwd.bk >/dev/null 2>&1|| cp /etc/passwd /etc/passwd.bk
cat /etc/passwd |grep zabbix |sed -r 's#(^.*)(::.*$)#\1:zabbix:/home/zabbix/:/bin/bash#g' >/script/qx.txt
sed -i '/zabbix/d' /etc/passwd
cat /script/qx.txt >>/etc/passwd
cat /etc/sudoers |grep zabbix >/dev/null 2>&1|| sed '20 azabbix  ALL=(ALL:ALL) ALL' -i /etc/sudoers
cat /etc/sudoers |grep NOPASSWD|grep zabbix >/dev/null 2>&1||echo 'zabbix ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers
ls /home/zabbix/ >/dev/null 2>&1|| mkdir -p /home/zabbix/
ls /home/zabbix/ >/dev/null 2>&1&& chown -R zabbix.zabbix /home/zabbix/
ls /home/zabbix/ >/dev/null 2>&1&& cp /etc/skel/.bash* /home/zabbix/
systemctl restart  zabbix-agent
systemctl status  zabbix-agent
curl cip.cc && echo 'END'
#===================================================↓END↓===================================================#