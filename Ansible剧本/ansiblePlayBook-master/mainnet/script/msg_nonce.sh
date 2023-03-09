#!/bin/bash
set -ue

##################修改下面四个参数####################################
Wallet=f3vdsvcy2an53u3erjkpjipgi2gsaogghqqlmwcia6hwfxynrdgeef5cm6jr4n4pn7gzmdplyephvvvpoe4cdq #自己的钱包地址
GS=51568205           #增加的gas Feecap价格
BaseFeeMAX=1200000000  #设置gas Feecap的上限;如果计算的gas Feecap价格大于这个预设值,则该条消息不加价格
Number=4000            #每次处理的消息数量=Number/4, 1000则代表处理250条消息
#####################################################################

Balance=`~/bin/lotus wallet balance $Wallet |awk -F '.' '{print $1}'`
NoMsg=`bin/lotus mpool stat --local|grep $Wallet |awk -F'[ ,]+' '{print $7}'`
NeedBalance=`echo "$NoMsg * 0.2 " |bc`

if [ ${Balance} -lt ${NeedBalance%.*} ];then
        echo "钱包余额不足,请充值再来"
        exit 1
fi

FilfoxData=`curl 'https://filfox.info/api/v0/stats/base-fee?samples=1'`
BaseFee=`echo $FilfoxData | awk -F '"' '{print $8}'`

if [ $BaseFee -ge 5000000000 ] && [ $1 != "force" ];then
        exit 1
fi

#GasFeecap6=${BaseFee:-2551568205}
#GasFeecap7=${BaseFee:-2051568205}
echo $BaseFee

~/bin/lotus mpool pending --local | awk -F '[ ,"]+' '/Method/||/Nonce/||/GasPremium/||/GasFeeCap/{print $(NF-1)}' | head -$Number >/tmp/nonce.txt

timestamp=$(date +%s)
ls /tmp/GasFeecap6 | echo "1"> /tmp/GasFeecap6
ls /tmp/GasFeecap7 | echo "1"> /tmp/GasFeecap7

while [ -s /tmp/nonce.txt ];do
        Nonce=`sed -n '1,1p' /tmp/nonce.txt`
        GasFeeCap=`sed -n '2,2p' /tmp/nonce.txt`
        GasPremium=`sed -n '3,3p' /tmp/nonce.txt`
        Method=`sed -n '4,4p' /tmp/nonce.txt`
        sed -i '1,4d' /tmp/nonce.txt
        endGasPremium=`echo "$GasPremium * 1.25 + 1 " |bc`
        #if [ $GasPremium -lt 10000 ];then
        #        endGasPremium=147500
        #fi
        #endGasPremium=100001475
        if [ $Method -eq 6 ];then
                GasFeecap6=`echo "$BaseFee + $GS "|bc`
                #GasFeecap6=`echo "($BaseFee + $GasFeeCap) * 1 + $GS "|bc`
                echo $GasFeecap6
                if [ $GasFeecap6 -ge $BaseFeeMAX ];then
                        echo "$Nonce 原消息价格已经超过预设值最大值,不进行增加价格"
                        continue
                fi

                oldGasFeecap6=`cat /tmp/GasFeecap6`
                GasFeecap6filetimestamp=$(stat -c %Y /tmp/GasFeecap6)
                timecha=`echo "$timestamp - $GasFeecap6filetimestamp"|bc`
                if [ $timecha -lt 300 ] && [ ${GasFeeCap%.*} -eq ${oldGasFeecap6%.*} ] || [ ${GasFeeCap%.*} -ge ${GasFeecap6%.*} ];then
                        echo "$Nonce 无需修改,稍休息几分钟后再试"
                        exit 1
                fi
                echo "6类消息，Nonce 为:$Nonce; 增加endGasPremium到:${endGasPremium%.*},增加GasFeecap到:${GasFeecap6%.*}"
                ~/bin/lotus mpool replace --skip-commit=false --auto=false --gas-premium=${endGasPremium%.*} --gas-feecap=${GasFeecap6%.*} $Wallet $Nonce
        elif [ $Method -eq 7 ];then
                GasFeecap7=`echo "$BaseFee + $GS "|bc`
                #GasFeecap7=`echo "($BaseFee + $GasFeeCap) * 1 + $GS "|bc`
                if [ $GasFeecap7 -ge $BaseFeeMAX ];then
                        echo "$Nonce 原消息价格已经超过预设值最大值,不进行增加价格"
                        continue
                fi

                oldGasFeecap7=`cat /tmp/GasFeecap7`
                GasFeecap7filetimestamp=$(stat -c %Y /tmp/GasFeecap7)
                timecha=`echo "$timestamp - $GasFeecap7filetimestamp"|bc`
                if [ $timecha -lt 300 ] && [ ${GasFeeCap%.*} -eq ${oldGasFeecap7%.*} ] || [ ${GasFeeCap%.*} -ge ${GasFeecap7%.*} ];then
                        echo "$Nonce 无需修改,稍休息几分钟后再试"
                        exit 1
                fi
                echo "7类消息，Nonce 为:$Nonce; 增加endGasPremium到:${endGasPremium%.*},增加GasFeecap到:${GasFeecap7%.*}"
                ~/bin/lotus mpool replace --skip-commit=false --auto=false --gas-premium=${endGasPremium%.*} --gas-feecap=${GasFeecap7%.*} $Wallet $Nonce
        else
                echo "${Method}类消息，Nonce 为:$Nonce; 无操作"
        fi
done

#echo ${GasFeecap6%.*} |tee /tmp/GasFeecap6
#echo ${GasFeecap7%.*} |tee /tmp/GasFeecap7