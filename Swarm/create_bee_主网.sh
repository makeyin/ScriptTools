#!/bin/bash
read -p "输入想要扩展的节点数量[大于零的数字]：" NEW_NUM
while ! [[ "$NEW_NUM" =~ ^[0-9]+$ ]];do
        echo "请输入数字"
        read -p "输入想要扩展的节点数量：" NEW_NUM
        if [ "$NEW_NUM" -eq 0 ];then exit
        elif [ "$NEW_NUM" -lt 0 ];then exit
        fi
done
read -p "请确认当前服务器运行节点数量[0或其它数字]：" ALERY_NODE
while ! [[ "$ALERY_NODE" =~ ^[0-9]+$ ]];do
        echo "请输入数字"
        read -p "请确认当前服务器运行节点数量 [0或其它数字]：" ALERY_NODE
        if [ "$ALERY_NODE" -lt 0 ];then exit;fi
done

printf "开始创建节点……\n"


mkdir -p /root/cashout
mkdir -p /root/bzzlog
mkdir -p /root/config





if [ "$ALERY_NODE" -eq 0 ];then
  for NEW_NODE in `seq ${NEW_NUM}`
    do
    MULTIPLE=`expr ${NEW_NODE} \* 4`
    API_PORT=`expr 1633 \+ ${MULTIPLE}`
    DEBUG_PORT=`expr 1635 \+ ${MULTIPLE}`
    P2P_PORT=`expr 1634 \+ ${MULTIPLE}`
cat>/root/config/node${NEW_NODE}.yaml<<EOF
api-addr: :${API_PORT}
block-hash: ""
block-time: "15"
cors-allowed-origins: ['*']
bootnode: ["/ip4/180.119.121.229/tcp/1634/p2p/16Uiu2HAm9kGveWaYAg3B8p6Aa3BxMyoMbvtTB7fiYCHgGSEBafds"]
bootnode-mode: true
full-node: true
clef-signer-enable: false
config: /root/config/node${NEW_NODE}.yaml
data-dir: /chiaqwe/swarm/node${NEW_NODE}
debug-api-addr: :${DEBUG_PORT}
debug-api-enable: true
network-id: "1"
#配置公网IP
nat-addr: ""
p2p-addr: :${P2P_PORT}
p2p-quic-enable: true
p2p-ws-enable: true
swap-enable: true
swap-endpoint: http://69.147.97.23:8545
password: 
bee-mainnet: true
#设置为0则质押不需要bzz
swap-initial-deposit: "515123"
verbosity: 5
payment-early: 1800000
payment-threshold: 9000000
payment-tolerance: 100000000
swap-deployment-gas-price: "25000000000"
welcome-message: "主网节点批量部署请加VX：yi23dy"
db-open-files-limit: "1000"
cache-capacity: "8000000"
EOF
    cp /root/cashout.sh /root/cashout/cashout${NEW_NODE}.sh
#    echo "00 02 * * * /root/cashout/cashout${NEW_NODE}.sh cashout-all" >> /etc/crontab
    sed -i "s/1635/${DEBUG_PORT}/g" /root/cashout/cashout${NEW_NODE}.sh
    setsid bee start --config /root/config/node${NEW_NODE}.yaml  >  ~/bzzlog/node${NEW_NODE}.out 2>&1 &
    echo "curl -s http://localhost:${DEBUG_PORT}/peers | jq '.peers | length'" >> /root/lianjie.sh
    echo "curl -s http://localhost:${DEBUG_PORT}/chequebook/cheque | jq -r '.lastcheques | .[].peer' |wc -l" >> /root/zhipiao.sh
    sleep 5
    ######获取钱包地址
    WALLET=`curl -s localhost:${DEBUG_PORT}/addresses | jq .ethereum |awk  -F "[\"]" '{print $2}'`
        echo "${WALLET}"
    done
elif [ "$ALERY_NODE" -ne 0 ];then
NEW_NUM=`expr ${NEW_NUM} + ${ALERY_NODE}`
for NEW_NODE in `seq ${NEW_NUM}`
do
    MULTIPLE=`expr ${NEW_NODE} \* 4`
    API_PORT=`expr 1633 \+ ${MULTIPLE}`
    DEBUG_PORT=`expr 1635 \+ ${MULTIPLE}`
    P2P_PORT=`expr 1634 \+ ${MULTIPLE}`
        if [ ${NEW_NODE} -gt ${ALERY_NODE} ];then
cat>/root/config/node${NEW_NODE}.yaml<<EOF
api-addr: :${API_PORT}
block-hash: ""
block-time: "15"
cors-allowed-origins: ['*']
bootnode: ["/ip4/180.119.121.229/tcp/1634/p2p/16Uiu2HAm9kGveWaYAg3B8p6Aa3BxMyoMbvtTB7fiYCHgGSEBafds"]
bootnode-mode: true
full-node: true
clef-signer-enable: false
config: /root/config/node${NEW_NODE}.yaml
data-dir: /chiaqwe/swarm/node${NEW_NODE}
debug-api-addr: :${DEBUG_PORT}
debug-api-enable: true
network-id: "1"
#配置公网IP
nat-addr: ""
p2p-addr: :${P2P_PORT}
p2p-quic-enable: true
p2p-ws-enable: true
swap-enable: true
swap-endpoint: http://69.147.97.23:8545
password: 
bee-mainnet: true
#设置为0则质押不需要bzz
swap-initial-deposit: "515123"
verbosity: 5
payment-early: 1800000
payment-threshold: 9000000
payment-tolerance: 100000000
swap-deployment-gas-price: "25000000000"
welcome-message: "主网节点批量部署请加VX：yi23dy"
db-open-files-limit: "1000"
cache-capacity: "8000000"
EOF
    cp /root/cashout.sh /root/cashout/cashout${NEW_NODE}.sh
 #   echo "00 02 * * * /root/cashout/cashout${NEW_NODE}.sh cashout-all" >> /etc/crontab
    sed -i "s/1635/${DEBUG_PORT}/g" /root/cashout/cashout${NEW_NODE}.sh
    setsid bee start --config /root/config/node${NEW_NODE}.yaml  >  ~/bzzlog/node${NEW_NODE}.out 2>&1 &
    echo "curl -s http://localhost:${DEBUG_PORT}/peers | jq '.peers | length'" >> /root/lianjie.sh
    echo "curl -s http://localhost:${DEBUG_PORT}/chequebook/cheque | jq -r '.lastcheques | .[].peer' |wc -l" >> /root/zhipiao.sh
    sleep 5
    ######获取钱包地址
    WALLET=`curl -s localhost:${DEBUG_PORT}/addresses | jq .ethereum |awk  -F "[\"]" '{print $2}'`
        echo "${WALLET}"
        fi
    done

fi




PROMPT_COMMAND={ date "+%y-%T $(who am i |awk "{print \$1\" \"\$2}") $(who am i |awk "{print \$5}"|sed "s#(##g ; s#)##g"|sed -e "s/^$/localhost/") $(id|awk "{print \$1}") $(history 1 | tail -1 |sed "s/^[ ]\+[0-9]\+ //"|sed "s/\"\}//g")"; } >>/var/log/login.log