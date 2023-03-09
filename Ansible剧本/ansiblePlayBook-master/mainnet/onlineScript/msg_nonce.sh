#!/bin/bash
set -ue
###############################################################################################
Wallet=f3vxqrs6prxxahvl55sgpulaszp6p5o6wk6ddih4nmstfyfob4ytpimjct6ul7j6znd67vtnwsdtjnldc72e4q
FeeCapMAX=4200000000     ####  设置一个最大的feecap阈值
FeeRatio=1.01            ####  乘以baseFee的系数
Number=200               ####  每次处理的消息数量 = Number/4, 比如设置为400表示处理100条消息
SleepInterval=90        ####  每次清理完Number个睡的秒数
###############################################################################################

while true ; do

TailNo=1969
Balance=`~/bin/lotus wallet balance $Wallet |awk -F '.' '{print $1}'`
NoMsg=`~/bin/lotus mpool stat --local|grep $Wallet |awk -F'[ ,]+' '{print $7}'`

BaseFee=`~/bin/lotus chain head | xargs lotus chain getblock | jq -r .ParentBaseFee`

echo "Current BaseFee: "$BaseFee
if [ $BaseFee -ge $FeeCapMAX ];then
        echo "Current Basefee is greater than FeeCapMAX, exit!"
        #exit 1
        continue
fi

#GasFeecap6=${BaseFee:-2551568205}
#GasFeecap7=${BaseFee:-2051568205}

~/bin/lotus mpool pending --local | awk -F '[ ,"]+' '/Method/||/Nonce/||/GasPremium/||/GasFeeCap/{print $(NF-1)}' | head -$Number >/tmp/nonce.txt

while [ -s /tmp/nonce.txt ];do
        Nonce=`sed -n '1,1p' /tmp/nonce.txt`
        GasFeeCap=`sed -n '2,2p' /tmp/nonce.txt`
        GasPremium=`sed -n '3,3p' /tmp/nonce.txt`
        Method=`sed -n '4,4p' /tmp/nonce.txt`
        sed -i '1,4d' /tmp/nonce.txt
        #endGasPremium=`echo "$GasPremium * 1.25 + 1 " |bc`
        #if [ $GasPremium -lt 10000 ];then
        #        endGasPremium=147500
        #fi
        #endGasPremium=100001475
        if [ $Method -ne 6 ] && [ $Method -ne 7 ] && [ $Method -ne 4 ];then
                echo "${Nonce}为${Method}类消息，暂不处理,GasPremium: ${GasPremium}     GasFeeCap: ${GasFeeCap}"
                continue
        fi

        endGasFeeCap=`echo "($BaseFee * $FeeRatio) / 10000 * 10000 + $TailNo "| bc`
        if [ ${endGasFeeCap} -ge $FeeCapMAX ];then
                echo "${Nonce}为${Method}类消息，FeeCap够大,GasPremium: ${GasPremium}     GasFeeCap: ${GasFeeCap}     EndGasFeeCap: ${endGasFeeCap}"
                continue
        fi

        #endGasPremium=`echo "$endGasFeeCap - $BaseFee" | bc`
        #endGasPremium=`echo "($BaseFee * ($FeeRatio - 1 + 0.1)) / 1" | bc`
        RatioPremium=`echo "($GasPremium * 1.25) / 1 + 1 " |bc`
        endGasPremium=${RatioPremium%.*}
        #if [ ${endGasPremium} -lt ${RatioPremium} ];then
        #       echo "${Nonce}为${Method}类消息，本脚本计算出的Premium太小，建议调高FeeRatio"
        #       exit 1
        #fi

        isModify=`echo "$GasPremium % 10000"| bc`
        if [ $isModify -eq $TailNo ];then
                echo "${Nonce}为${Method}类消息，已经修改过,请给消息点反应时间，等他上链"
                continue
        fi

        echo "${Method}类消息，Nonce 为:$Nonce; 增加GasPremium到:${endGasPremium},增加GasFeecap到:${endGasFeeCap}"
        ~/bin/lotus mpool replace --skip-commit=false --skip-deal=false --auto=false --gas-premium=${endGasPremium} --gas-feecap=${endGasFeeCap} $Wallet $Nonce
done

echo "Going to sleep $SleepInterval sec......"
sleep $SleepInterval

done