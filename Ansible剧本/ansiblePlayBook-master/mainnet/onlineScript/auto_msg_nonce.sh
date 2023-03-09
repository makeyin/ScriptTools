#!/bin/bash
set -ue
############################设置为需要清理的节点的worker钱包地址##################################
Wallet=f3w2t7neo6vfdh44akq2637x54bh5o6eue5kernlb53dkv4pqhhz7kmtbm5o7zlwmlkp2m7frsnqjjy5k5a7ja    
BaseFeeMAX=10000000000   ####  设置为经过商务组同意的最大上消息的全网base费用
FeeRatio=1.2             ####  乘以baseFee的系数; 默认值为1.01, 如果拥堵严重, 可以上调为1.05
MsgNumber=60             ####  每次修改多少条消息的价格, 建议不要超过100
SleepInterval=120         ####  每次清理完睡的秒数, 不要设置太小, 否则上一次修改的消息还没有来得及上链导致重复修改
################################################################################################

while true ; do
        TailNo=1969
        NonceFile="/tmp/nonceNew.txt"
        Balance=`~/bin/lotus wallet balance $Wallet |awk -F '.' '{print $1}'`
        NoMsg=`~/bin/lotus mpool stat --local|grep $Wallet |awk -F'[ ,]+' '{print $7}'`

        let Number=$MsgNumber*4
        ~/bin/lotus mpool pending --local --from $Wallet | awk -F '[ ,"]+' '/Method/||/Nonce/||/GasPremium/||/GasFeeCap/{print $(NF-1)}' | head -$Number > $NonceFile
        sleep 5

        BaseFee=`~/bin/lotus chain head | xargs lotus chain getblock | jq -r .ParentBaseFee`
        echo "Current BaseFee: "$BaseFee
        if [ $BaseFee -ge $BaseFeeMAX ];then
                echo -e "\033[31m当前 Basefee 大于设定最大FeeCap值${BaseFeeMAX} ! Going to sleep $SleepInterval sec...... \033[0m"
                sleep $SleepInterval
                continue
        fi

        while [ -s $NonceFile ];do
                Nonce=`sed -n '1,1p' $NonceFile`
                GasFeeCap=`sed -n '2,2p' $NonceFile`
                GasPremium=`sed -n '3,3p' $NonceFile`
                Method=`sed -n '4,4p' $NonceFile`
                sed -i '1,4d' $NonceFile

                #if [ $Method -ne 6 ] && [ $Method -ne 7 ] && [ $Method -ne 4 ];then
                #        echo "${Nonce}为${Method}类消息，暂不处理,GasPremium: ${GasPremium}     GasFeeCap: ${GasFeeCap}"
                #        continue
                #fi

                #isModify=`echo "$GasPremium % 10000"| bc`
                #if [ $isModify -eq $TailNo ];then
                #        echo "消息: ${Nonce}, 类型: ${Method}, 该消息之前已经被处理过,跳过该消息"
                #        continue
                #fi

                endGasFeeCap=`echo "($BaseFee * $FeeRatio) / 1"| bc`
                # if [ ${endGasFeeCap} -ge $FeeCapMAX ];then
                #         echo -e "\033[31m 消息Nonce: ${Nonce}, 类型: ${Method}, 计算后的FeeCap大于设定最大FeeCap值${FeeCapMAX}, 跳过该消息. 原GasFeeCap: ${GasFeeCap}, 计算后的GasFeeCap: ${endGasFeeCap} \033[0m"
                #         continue
                # fi

                #### 如果原来的GasFeeCap在baseFee的 FeeRatio范围内, 

                RatioPremium=`echo "($GasPremium * 1.25) / 1 + 1 " |bc`
                endGasPremium=${RatioPremium%.*}

                echo -e "\033[34m 消息Nonce:\033[0m \033[32m ${Nonce} \033[0m, \033[34m类型: ${Method}, 调整GasPremium为:${GasPremium}-->${endGasPremium}, 调整GasFeecap为:${GasFeeCap}-->${endGasFeeCap}  \033[0m"
                ~/bin/lotus mpool replace --skip-commit=false --skip-deal=false --auto=false --gas-premium=${endGasPremium} --gas-feecap=${endGasFeeCap} $Wallet $Nonce || true
        done

        echo "Going to sleep $SleepInterval sec......"
        sleep $SleepInterval

done