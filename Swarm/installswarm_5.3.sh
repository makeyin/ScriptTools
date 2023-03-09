######获取bee进程号
install(){
######下载并安装所需组件
#BeeClef="bee-clef_0.4.9_amd64.deb"
#Bee="bee_0.5.3_amd64.deb"
wget https://github.com/ethersphere/bee-clef/releases/download/v0.4.12/bee-clef_0.4.12_amd64.deb > /dev/null 2>/dev/null && dpkg -i bee-clef_0.4.12_amd64.deb  > /dev/null 2>/dev/null
#sleep 60
#nohup dpkg -i ${BeeClef} > /dev/null 2>/dev/null &
#sleep 60
#which bee-clef-service > /dev/null 2>/dev/null
#if [ $? -ne 0 ];theßn
#       nohup dpkg -i ${BeeClef} > /dev/null 2>/dev/null &
#       sleep 60
#fi

#Bee="bee_0.5.3_amd64.deb"
wget https://github.com/ethersphere/bee/releases/download/v0.6.2/bee_0.6.2_amd64.deb > /dev/null 2>/dev/null && dpkg -i bee_0.6.2_amd64.deb > /dev/null 2>/dev/null
#sleep 60
#nohup dpkg -i ${Bee} > /dev/null > /dev/null 2>/dev/null &
#sleep 60
#which bee > /dev/null 2>/dev/null

#if [ $? -ne 0 ];then
#       nohup dpkg -i ${Bee} > /dev/null > /dev/null 2>/dev/null &
#       sleep 60
#fi

######编写密码文件
echo "yi23dy" > /root/.bee-password-file
echo "* soft nofile 10240" >> /etc/security/limits.conf
echo "* hard nofile 10240" >> /etc/security/limits.conf
######安装必须组件
apt-get update > /dev/null 
apt install jq htop cpulimit curl -y  > /dev/null 2>/dev/null 
sleep 60

#######提支票&守护进程
cat >>/root/cashout.sh<<'EOF'
#!/usr/bin/env bash
[ -z ${DEBUG_API+x} ] && DEBUG_API=http://localhost:1635	
[ -z ${MIN_AMOUNT+x} ] && MIN_AMOUNT=10000000000000000	

# cashout script for bee >= 0.6.0
# note this is a simple bash script which might not work well or at all on some platforms
# for a more robust interface take a look at https://github.com/ethersphere/swarm-cli

function getPeers() {	
  curl -s "$DEBUG_API/chequebook/cheque" | jq -r '.lastcheques | .[].peer'	
}

function getUncashedAmount() {  
  curl -s "$DEBUG_API/chequebook/cashout/$1" | jq '.uncashedAmount'  
}

function cashout() {
  local peer=$1
  txHash=$(curl -s -XPOST "$DEBUG_API/chequebook/cashout/$peer" | jq -r .transactionHash)
  echo cashing out cheque for $peer in transaction $txHash >&2
}

function cashoutAll() {
  local minAmount=$1
  for peer in $(getPeers)
  do
    local uncashedAmount=$(getUncashedAmount $peer)
    if (( "$uncashedAmount" > $minAmount ))
    then
      echo "uncashed cheque for $peer ($uncashedAmount uncashed)" >&2
      cashout $peer
    fi
  done
}

function listAllUncashed() {
  for peer in $(getPeers)
  do
    local uncashedAmount=$(getUncashedAmount $peer)
    if (( "$uncashedAmount" > 0 ))
    then
      echo $peer $uncashedAmount
    fi
  done
}

case $1 in
cashout)
  cashout $2
  ;;
cashout-all)
  cashoutAll $MIN_AMOUNT
  ;;
uncashed-for-peer)
  getUncashedAmount $2
  ;;
list-uncashed|*)
  listAllUncashed
  ;;
esac
EOF

cat >>/root/shouhu.sh<<'EOF'
#!/bin/sh
PRO_NAME=endpoint
while true ; do
     NUM=`ps aux | grep -w ${PRO_NAME} | grep -v grep |wc -l`
     xianchen=`ps aux | grep -w ${PRO_NAME} | grep -v grep | awk '{print $2}'`
     #少于1，重启进程
     if [ "${NUM}" -lt "1" ];then
         echo "${PRO_NAME} was killed"
         nohup bee start --verbosity 3 --swap-endpoint  http://107.150.6.165:8545   --debug-api-enable --full-node  --clef-signer-enable   --clef-signer-endpoint /var/lib/bee-clef/clef.ipc  --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &

    #大于1，杀掉所有进程，重启
    elif [ "${NUM}" -gt "1" ];then
        echo "more than 1 ${PRO_NAME},killall ${PRO_NAME}"
         kill -9 ${xianchen}
         nohup bee start --verbosity 3 --swap-endpoint  http://107.150.6.165:8545   --debug-api-enable  --clef-signer-enable  --full-node  --clef-signer-endpoint /var/lib/bee-clef/clef.ipc  --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &

     fi
     #kill僵尸进程
     NUM_STAT=`ps aux | grep -w ${PRO_NAME} | grep T | grep -v grep | wc -l`
     if [ "${NUM_STAT}" -gt "0" ];then
         kill -9 ${xianchen}
         nohup bee start --verbosity 3 --swap-endpoint  http://107.150.6.165:8545   --debug-api-enable  --clef-signer-enable --full-node  --clef-signer-endpoint /var/lib/bee-clef/clef.ipc  --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &

    fi
     sleep 5s
 done
 
 exit 0
EOF
chmod +x /root/cashout.sh
chmod +x /root/shouhu.sh
##清理环境
rm -rf /root/bee-clef_0.4.12_amd64.deb
rm -rf /root/bee_0.6.2_amd64.deb


######启动bee
nohup bee start --verbosity 3 --swap-endpoint  http://107.150.6.165:8545   --debug-api-enable  --clef-signer-enable  --full-node --clef-signer-endpoint /var/lib/bee-clef/clef.ipc  --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &
#nohup sh /root/shouhu.sh > /root/restartbee.log 2>&1 &
sleep 45
######获取钱包地址
WALLET=`grep "cannot continue until there is sufficient ETH" /root/bee-start-info.log |awk -F 'on' '{print $3}' |awk '{print $1}'|awk -F '"' '{print $1}'|uniq `

#IP=`ip a | grep global | awk '{print $2}' | awk -F'/' '{print $1}'`

echo "${WALLET}"
}

start(){
PORT_NUM=`ss -anpt | grep LISTEN | grep -E ":1633|:1634|:1635" | wc -l` > /dev/null
if [ ${PORT_NUM} -ne 4 ];then
        killall bee 2>/dev/null
        sleep 3
               nohup bee start --verbosity 3 --swap-endpoint  http://107.150.6.165:8545   --debug-api-enable  --clef-signer-enable --full-node  --clef-signer-endpoint /var/lib/bee-clef/clef.ipc  --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &
               #nohup sh /root/shouhu.sh > /root/restartbee.log 2>&1 &
                sleep 30
                WALLET=`grep "cannot continue until there is sufficient ETH" /root/bee-start-info.log |awk -F 'on' '{print $3}' |awk '{print $1}'|awk -F '"' '{print $1}'|uniq `
                if [ -n "${WALLET}" ];then
                        echo ${WALLET}
                        exit
                fi
else
                echo "swarm already runing"
                exit
fi
}


for i in `seq 5`
do
        pid_num=`ss -anpt | grep LISTEN | grep bee |wc -l`
        bee_commond=`which bee | wc -l`
        ps -ef | grep "bee-clef-service start" | grep -v grep > /dev/null
        if [ $? -ne 0 ];then
                systemctl start bee-clef.service 2>> /dev/null
                if [ $? -ne 0 ];then
                        echo "install swarm……"
                        install
                        exit
                fi
        elif [ ${bee_commond} -ne 1 ];then
                echo "install swarm bee……"
                install
                exit
        elif [ ${pid_num} -ne 4 ];then
                echo "start swarm……"
                start
        else
                echo "swarm already runing"
                exit
        fi
        sleep 50
done