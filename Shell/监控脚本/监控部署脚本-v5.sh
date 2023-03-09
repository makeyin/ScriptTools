#!/bin/bash
#本脚本作者对执行后的一切后果不负责！请慎重执行！

homeuser=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $8}' |head -n1`
user=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $9}' |head -n1`

#判断是否为root执行
yh=`whoami |grep root |wc -l`
if [ $yh -ne 1 ];then
	echo -e "\033[41;37m                   请使用root执行                        \033[0m"
	exit 1
fi

if [ ! -n "$1" ] ;then
	echo "请在脚本后加上被监控机编号：节点号-机器IP后2段（t014XXX-xx.xx）"
	exit 1
fi

if [ ! -n "$2" ] ;then
	echo "请在脚本后加上监控机IP地址"
	exit 1
fi

ls /etc/zabbix/zabbix_agentd.conf >/dev/null 2>&1 && echo 'Hostname为' `cat /etc/zabbix/zabbix_agentd.conf |awk -F '=' '/Hostname/{print $2}'`

#判断是否有lotus相关进程，有就安装zabbix-agent。
panduan=`ps -ef |grep 'lot[us]' |awk 'NR==1{print $8}'|wc -l`
if [ $panduan -lt 1 ];then
exit 1
else
echo -e "\033[41;37m                   Warning                        \033[0m"
echo -e "\033[41;37m 本脚本作者对执行后的一切后果不负责！请慎重执行！ \033[0m"
echo -e "\033[42;37m                     GO                           \033[0m"
sleep 2
dpkg -s zabbix-agent >/dev/null 2>&1
if [ $? -ne 0 ];then
		echo -e "\033[42;37m检测出未安装zabbix-agent，正在安装请等待。。。。 \033[0m"
		apt-get  install zabbix-agent -y >/dev/null 2>&1
		sleep 1
#read -p "请输入被监控机编号：节点号-机器IP后2段（t014XXX-xx.xx）:" hostname
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
		echo -e "\033[42;37m zabbix-agent安装完成\033[0m"
mkdir -p  /etc/zabbix/zabbix_agentd.d
mkdir -p /var/log/zabbix/
touch /var/log/zabbix/zabbix_agentd.log
chown  zabbix.zabbix /var/log/zabbix/zabbix_agentd.log
chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d
chown -R zabbix.zabbix /var/log/zabbix
systemctl restart  zabbix-agent
else
		echo -e "\033[42;37m zabbix-agent已经安装\033[0m"
fi
fi

#判断是否有/script目录
if [ ! -d /script/jkxx ];then
mkdir -p /script/jkxx
fi

sleep 1

##############################################################################################################################################lotus
##############################################################################################################################################
sleep 3
lts=`ps -ef |grep 'lotus daem[on]' |wc -l`
if [ $lts -ge 1 ];then
cat >/script/lotus-course.sh<<'EOF'
#!/bin/bash

ps -ef |grep '[l]otus daemon'|wc -l
EOF

disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`

echo "UserParameter=disk.check,bash /script/disk_check.sh" > /etc/zabbix/zabbix_agentd.d/disk_check.conf
echo "UserParameter=bin.version,bash /script/bin_version.sh" > /etc/zabbix/zabbix_agentd.d/bin_version.conf

touch /script/jkxx/new_disklist.txt
touch /script/jkxx/disk_check.txt

echo $disk_tank > /script/jkxx/disk_check.txt
for i in $disk_tank
do
    touch $i/disk_status.txt && chown zabbix.zabbix $i/disk_status.txt
done

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

cat>/script/disk_check.sh<<'EOF'
#!/bin/bash
disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`
echo $disk_tank > /script/jkxx/new_disklist.txt
result=`diff /script/jkxx/disk_check.txt /script/jkxx/new_disklist.txt`
if [ ! $result ];then
    for i in $disk_tank
    do
        echo "check_status!" > $i/disk_status.txt
        if [ "$?" -eq "0" ];then
            echo "0"
        else
            echo "$i磁盘异常，请上机检查！"
            exit
        fi
    done
else
    echo "请检查：$result!"
fi
EOF

cat >/script/xxdl.sh<<'EOF'
#!/bin/bash

#$1=lotus在什么用户下
#$2=cur6/futrue8
sudo runuser -l goodli -c '/home/goodli/bin/lotus mpool stat --local'|awk -F '[, ;]+' '/total/{print $'$2'}'
EOF

cat  >/script/hostnametest.sh<<'EOF'
#!/bin/bash

hosts=`grep "127.0.0.1 $(hostname)" /etc/hosts |wc -l`
if [ $hosts -eq 0 ];then
echo "127.0.0.1 `hostname`" >>/etc/hosts
echo 0
else
echo 1
fi
EOF

cat >/etc/zabbix/zabbix_agentd.d/hostnametest.conf<<'EOF'
UserParameter=jchosts,sudo bash /script/hostnametest.sh
EOF

cat >/script/qukuaiyc.sh<<'EOF'
#!/bin/bash

qk=`sudo runuser -l goodli -c '/home/goodli/bin/lotus chain head | head -1 | xargs -L1 ~/bin/lotus chain getblock | grep Timestamp'|awk -F'[ :,]+' '{print $3}'`
bd=`date +%s`
sj=`expr $bd - $qk`
echo $sj
EOF

homeuser=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
userfull=`ps -ef |grep '/bin/lot[us]' |awk -F '[ /]+' '{print $9}' |head -n1`


sed -i "s#goodli#$userfull#g" /script/xxdl.sh
sed -i "s#home#$homeuser#g" /script/xxdl.sh
sed -i "s#goodli#$userfull#g" /script/qukuaiyc.sh
sed -i "s#home#$homeuser#g" /script/qukuaiyc.sh

cat >/etc/zabbix/zabbix_agentd.d/xxdl.conf<<'EOF'
UserParameter=curxx,sudo bash /script/xxdl.sh goodli 6
UserParameter=futxx,sudo bash /script/xxdl.sh goodli 8
EOF

cat >/etc/zabbix/zabbix_agentd.d/lotus-course.conf<<'EOF'
UserParameter=lotus,bash /script/lotus-course.sh
EOF

cat >/etc/zabbix/zabbix_agentd.d/block-lag-time.conf<<'EOF'
UserParameter=blt,bash /script/qukuaiyc.sh
EOF

sed -i "s#goodli#$userfull#g" /etc/zabbix/zabbix_agentd.d/xxdl.conf
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
grep "127.0.0.1 `hostname`" /etc/hosts >/dev/null 2>&1 || echo "127.0.0.1  `hostname`" >>/etc/hosts
fi
##############################################################################################################################################power
##############################################################################################################################################
sleep 3
pwr=`ps -ef |grep 'lotus-power r[un]' |wc -l`
if [ $pwr -ge 1 ];then
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

disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`

echo "UserParameter=disk.check,bash /script/disk_check.sh" > /etc/zabbix/zabbix_agentd.d/disk_check.conf
echo "UserParameter=bin.version,bash /script/bin_version.sh" > /etc/zabbix/zabbix_agentd.d/bin_version.conf

touch /script/jkxx/new_disklist.txt
touch /script/jkxx/disk_check.txt

echo $disk_tank > /script/jkxx/disk_check.txt
for i in $disk_tank
do
    touch $i/disk_status.txt && chown zabbix.zabbix $i/disk_status.txt
done

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

cat >/etc/zabbix/zabbix_agentd.d/powerconf.conf<<'EOF'
UserParameter=EMPCOC,sudo bash /script/powerconf.sh EnableManualPreCommitOnChain
UserParameter=MSTOL,sudo bash /script/powerconf.sh MaxSealTotal
EOF

cat >/script/powerconf.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |head -n1`
cat /$userjia/$user/.lotusminer/config.toml |grep $1 |grep -v '#'|awk -F '[= ]+' '{print $3}'
EOF

cat>/script/disk_check.sh<<'EOF'
#!/bin/bash
disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`
echo $disk_tank > /script/jkxx/new_disklist.txt
result=`diff /script/jkxx/disk_check.txt /script/jkxx/new_disklist.txt`
if [ ! $result ];then
    for i in $disk_tank
    do
        echo "check_status!" > $i/disk_status.txt
        if [ "$?" -eq "0" ];then
            echo "0"
        else
            echo "$i磁盘异常，请上机检查！"
            exit
        fi
    done
else
    echo "请检查：$result!"
fi
EOF

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

cat >/script/Available-balance.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r  |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |sort -n |head -n1`
token=`sudo cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
sudo runuser -l goodli -c 'export FULLNODE_API_INFO='$token' && /home/goodli/bin/lotus-power  info '|awk -F "[ .]+" '/Available/{print $3}'|grep -Ev '#|^$'|sed -n 1P
EOF

cat >/script/post-balance.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |sort -n |head -n1`
token=`sudo cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
good=`sudo runuser -l goodli -c 'export FULLNODE_API_INFO='$token' && /home/goodli/bin/lotus-power actor control list --verbose '|awk -F '[F.]' '{print $1}'|awk  '/control-'$1'/{print $NF}'`
echo $good >/tmp/post$1.log
sleep 3
cat -A /tmp/post$1.log |awk -F "[m$]" '{print $2}' >/tmp/post$1.txt
ls -l /tmp/post$1.log|grep 'rwx' >/dev/null 2>&1
if [ $? -ne 0 ];then
        chmod 777 /tmp/post$1*
fi
EOF

cat >/script/work-balance.sh<<'EOF'
#!/bin/bash

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}'|sort -n  |head -n1`
token=`sudo cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#'  |awk -F '"' '{print $2}'`
sudo runuser -l goodli -c 'export FULLNODE_API_INFO='$token' &&/home/goodli/bin/lotus-power info'|awk -F "[ .]+" '/Worker/{print $3}'|grep -Ev '#|^$'
EOF


cat >/script/lotus-miner-course.sh<<'EOF'
#!/bin/bash

ps -ef|grep '[l]otus-power run'|wc -l
EOF

cat  >/script/hostnametest.sh<<'EOF'
#!/bin/bash

hosts=`grep "127.0.0.1 $(hostname)" /etc/hosts |wc -l`
if [ $hosts -eq 0 ];then
echo "127.0.0.1 `hostname`" >>/etc/hosts
echo 0
else
echo 1
fi
EOF

cat >/etc/zabbix/zabbix_agentd.d/hostnametest.conf<<'EOF'
UserParameter=jchosts,sudo bash /script/hostnametest.sh
EOF


sed -i "s#goodli#$user#g" /script/work-balance.sh
sed -i "s#home#$homeuser#g" /script/work-balance.sh

sed -i "s#goodli#$user#g" /script/post-balance.sh
sed -i "s#home#$homeuser#g" /script/post-balance.sh

sed -i "s#goodli#$user#g" /script/Available-balance.sh
sed -i "s#home#$homeuser#g" /script/Available-balance.sh


cat >/etc/zabbix/zabbix_agentd.d/Available-balance.conf<<"EOF"
UserParameter=available,sudo bash /script/Available-balance.sh
EOF

cat >/etc/zabbix/zabbix_agentd.d/lotus-miner-course.conf<<"EOF"
UserParameter=lotus-miner,bash /script/lotus-miner-course.sh
EOF

cat >/etc/zabbix/zabbix_agentd.d/post-balance.conf<<"EOF"
UserParameter=post0.balance,bash /script/post-balance.sh 0 && sudo cat /tmp/post0.txt
UserParameter=post1.balance,bash /script/post-balance.sh 1 && sudo cat /tmp/post1.txt
UserParameter=post2.balance,bash /script/post-balance.sh 2 && sudo cat /tmp/post2.txt
UserParameter=post3.balance,bash /script/post-balance.sh 3 && sudo cat /tmp/post3.txt
EOF

cat >/etc/zabbix/zabbix_agentd.d/work-balance.conf<<"EOF"
UserParameter=worker,bash /script/work-balance.sh
EOF

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

cat >/etc/zabbix/zabbix_agentd.d/commtting.conf<<'EOF'
UserParameter=cmt4xx,expr `cat /script/jkxx/Committing.log |awk -F '[>:]' '/即将过期/{print $2}' |wc -l` / 2
EOF


cat >/etc/zabbix/zabbix_agentd.d/commtype.conf<<'EOF'
UserParameter=cmtfld,sudo bash /script/commtype.sh SectorStateCommitFailed
UserParameter=cmting,sudo bash /script/commtype.sh SectorStateCommitting
UserParameter=pcmting,sudo bash /script/commtype.sh SectorStatePreCommitting
UserParameter=psld,sudo bash /script/commtype.sh SectorStatePreSealed
UserParameter=sbct,sudo bash /script/commtype.sh SectorStateSubmitCommit
UserParameter=precmtwt,sudo bash /script/commtype.sh SectorStatePreCommitWait
EOF

chown $user.crontab /var/spool/cron/crontabs/$user
touch /script/jkxx/Committing.log
chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d
ln -s /script/jkxx/Committing.log /$homeuser/$user/overtime_commtting.log >/dev/null 2>&1
chmod -R 777 /script/
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
grep "127.0.0.1 `hostname`" /etc/hosts >/dev/null 2>&1 || echo "127.0.0.1  `hostname`" >>/etc/hosts
fi
##############################################################################################################################################poster
##############################################################################################################################################
sleep 3
pst=`ps -ef|grep 'lotus-poster r[un]' |wc -l`
if [ $pst -ge 1 ];then
cat >/script/poster-jc.sh<<'EOF'
#!/bin/bash

ps -ef |grep lotus-post[er]|wc -l
EOF

cat >/etc/zabbix/zabbix_agentd.d/poster-jc.conf<<'EOF'
UserParameter=posterjc,sudo sh /script/poster-jc.sh
EOF

chmod 777 -R /script/
chown zabbix.zabbix -R /etc/zabbix/zabbix_agentd.d/
systemctl restart zabbix-agent
fi
##############################################################################################################################################window
##############################################################################################################################################
sleep 3
userwin=`ps -ef |grep /bin/lotus-win[dow] |awk -F '[ /]+' '{print $9}' |head -n1`
widw=`ps -ef|grep 'lotus-window r[un]' |wc -l`
if [ $widw -ge 1 ];then
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

disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`

echo "UserParameter=disk.check,bash /script/disk_check.sh" > /etc/zabbix/zabbix_agentd.d/disk_check.conf
echo "UserParameter=bin.version,bash /script/bin_version.sh" > /etc/zabbix/zabbix_agentd.d/bin_version.conf

touch /script/jkxx/new_disklist.txt
touch /script/jkxx/disk_check.txt

echo $disk_tank > /script/jkxx/disk_check.txt
for i in $disk_tank
do
    touch $i/disk_status.txt && chown zabbix.zabbix $i/disk_status.txt
done

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

cat>/script/disk_check.sh<<'EOF'
#!/bin/bash
disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`
echo $disk_tank > /script/jkxx/new_disklist.txt
result=`diff /script/jkxx/disk_check.txt /script/jkxx/new_disklist.txt`
if [ ! $result ];then
    for i in $disk_tank
    do
        echo "check_status!" > $i/disk_status.txt
        if [ "$?" -eq "0" ];then
            echo "0"
        else
            echo "$i磁盘异常，请上机检查！"
            exit
        fi
    done
else
    echo "请检查：$result!"
fi
EOF

cat >/script/window-process.sh<<'EOF'
#!/bin/bash

ps -ef|grep lotus-wind[ow]|wc -l
EOF

cat >/script/window-card.sh<<'EOF'
#!/bin/bash

nvidia-smi -L | grep "GeForce RTX"| awk   '{print $3,$4}' |wc -l
EOF

cat  >/script/hostnametest.sh<<'EOF'
#!/bin/bash

hosts=`grep "127.0.0.1 $(hostname)" /etc/hosts |wc -l`
if [ $hosts -eq 0 ];then
echo "127.0.0.1 `hostname`" >>/etc/hosts
echo 0
else
echo 1
fi
EOF

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

echo 'UserParameter=faults,sudo bash /script/faults.sh' >/etc/zabbix/zabbix_agentd.d/faults.conf

cat >/etc/zabbix/zabbix_agentd.d/hostnametest.conf<<'EOF'
UserParameter=jchosts,sudo bash /script/hostnametest.sh
EOF

cat >/etc/zabbix/zabbix_agentd.d/window-card.conf<<'EOF'
UserParameter=windowcard,sudo sh /script/window-card.sh
EOF

cat >/etc/zabbix/zabbix_agentd.d/window-process.conf<<'EOF'
UserParameter=windowjc,sudo sh /script/window-process.sh
EOF

cat >/etc/zabbix/zabbix_agentd.d/peerid.conf<<'EOF'
UserParameter=peerid,sudo sh /script/peerid.sh |grep '失去' |wc -l
EOF
ls /$homeuser/$userwin/poster_peers.list >/dev/null 2>&1|| runuser -l $userwin -c '~/bin/lotus-window net peers' |awk -F '[,/ ]+' '{print $4,$1}' >>/$homeuser/$userwin/poster_peers.list
touch /$homeuser/$userwin/peerid.log
chown $userwin.filecoin /$homeuser/$userwin/peerid.log
chmod -R 777 /script/
chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d
ls /etc/passwd.bk >/dev/null 2>&1|| cp /etc/passwd /etc/passwd.bk
cat /etc/passwd |grep zabbix |sed -r 's#(^.*)(::.*$)#\1:zabbix:/home/zabbix/:/bin/bash#g' >/script/qx.txt
sed -i '/zabbix/d' /etc/passwd
cat /script/qx.txt >>/etc/passwd
cat /etc/sudoers |grep zabbix >/dev/null 2>&1|| sed '20 azabbix  ALL=(ALL:ALL) ALL' -i /etc/sudoers
cat /etc/sudoers |grep NOPASSWD|grep zabbix >/dev/null 2>&1||echo 'zabbix ALL=(ALL) NOPASSWD: ALL' >>/etc/sudoers
ls /home/zabbix/ >/dev/null 2>&1|| mkdir -p /home/zabbix/
ls /tmp/peerid.txt >/dev/null 2>&1||touch /tmp/peerid.txt
chmod 777 /tmp/peerid.txt
chown $userwin.filecoin /$homeuser/$userwin/poster_peers.list
ls /home/zabbix/ >/dev/null 2>&1&& chown -R zabbix.zabbix /home/zabbix/
ls /home/zabbix/ >/dev/null 2>&1&& cp /etc/skel/.bash* /home/zabbix/
systemctl restart  zabbix-agent
systemctl status  zabbix-agent
grep "127.0.0.1 `hostname`" /etc/hosts >/dev/null 2>&1 || echo "127.0.0.1  `hostname`" >>/etc/hosts
fi
##############################################################################################################################################winning
##############################################################################################################################################
sleep 3
wing=`ps -ef|grep 'lotus-winning r[un]' |wc -l`
if [ $wing -ge 1 ];then
cat >/script/winning-card.sh<<'EOF'
#!/bin/bash

nvidia-smi -L | grep "GeForce RTX"| awk   '{print $3,$4}' |wc -l
EOF

cat >/etc/zabbix/zabbix_agentd.d/winning-card.conf<<'EOF'
UserParameter=winningcard,sudo sh /script/winning-card.sh
EOF

disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`

echo "UserParameter=disk.check,bash /script/disk_check.sh" > /etc/zabbix/zabbix_agentd.d/disk_check.conf
echo "UserParameter=bin.version,bash /script/bin_version.sh" > /etc/zabbix/zabbix_agentd.d/bin_version.conf

touch /script/jkxx/new_disklist.txt
touch /script/jkxx/disk_check.txt

echo $disk_tank > /script/jkxx/disk_check.txt
for i in $disk_tank
do
    touch $i/disk_status.txt && chown zabbix.zabbix $i/disk_status.txt
done

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

cat>/script/disk_check.sh<<'EOF'
#!/bin/bash
disk_tank=`df -HT | grep /tank | sort -k 7 | awk '{print $7}'`
echo $disk_tank > /script/jkxx/new_disklist.txt
result=`diff /script/jkxx/disk_check.txt /script/jkxx/new_disklist.txt`
if [ ! $result ];then
    for i in $disk_tank
    do
        echo "check_status!" > $i/disk_status.txt
        if [ "$?" -eq "0" ];then
            echo "0"
        else
            echo "$i磁盘异常，请上机检查！"
            exit
        fi
    done
else
    echo "请检查：$result!"
fi
EOF


cat  >/script/hostnametest.sh<<'EOF'
#!/bin/bash

hosts=`grep "127.0.0.1 $(hostname)" /etc/hosts |wc -l`
if [ $hosts -eq 0 ];then
echo "127.0.0.1 `hostname`" >>/etc/hosts
echo 0
else
echo 1
fi
EOF

cat >/etc/zabbix/zabbix_agentd.d/hostnametest.conf<<'EOF'
UserParameter=jchosts,sudo bash /script/hostnametest.sh
EOF

cat >/script/winning-process.sh<<'EOF'
#!/bin/bash

ps -ef|grep '/bin/lotus-winni[ng]' |wc -l
EOF

cat >/etc/zabbix/zabbix_agentd.d/winning-process.conf<<'EOF'
UserParameter=winningprocess,sudo sh /script/winning-process.sh
EOF
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
grep "127.0.0.1 `hostname`" /etc/hosts >/dev/null 2>&1 || echo "127.0.0.1  `hostname`" >>/etc/hosts
fi
##############################################################################################################################################
######################################################时间ttssdasd#############################################################################
#!/bin/bash
pip3 install ntplib

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


cat >/etc/zabbix/zabbix_agentd.d/check_OStime.conf<<EOF 
UserParameter=checktime,sudo python3 /script/time.py
EOF

chown -R zabbix.zabbix /etc/zabbix/zabbix_agentd.d/check_OStime.conf
systemctl restart zabbix-agent.service

##############################################################################################################################################END
curl cip.cc
echo 'END'