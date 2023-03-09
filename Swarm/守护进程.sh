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











 #!/bin/sh
while true ; do
     PORT_NUM=`ss -anpt | grep LISTEN  | grep bee | wc -l`
         PID_NUM=`ps -ef | grep "bee start" | grep -v grep | awk '{print $2}'`
     #不等于4，重启进程
     if [ "${PORT_NUM}" -eq "0" ];then
                 kill -9 ${PID_NUM}
                 ps -ef | grep "bee-clef-service start" | grep -v grep
                 if [ $? -ne 0 ];then
                        systemctl start bee-clef
                 fi
        nohup bee start --verbosity 3 --swap-endpoint http://155.94.177.130:8545 --debug-api-enable --full-node --clef-signer-enable --clef-signer-endpoint /var/lib/bee-clef/clef.ipc --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &
     elif [ "${PORT_NUM}" -eq "1" ];then
                 ss -anpt | grep LISTEN | grep bee | awk '{print $NF}' | awk -F, '{print $2}' | awk -F= '{print $2}' | uniq | xargs kill -9
                 if [ $? -ne 0 ];then
                        systemctl start bee-clef
                 fi
                 nohup bee start --verbosity 3 --swap-endpoint http://155.94.177.130:8545 --debug-api-enable --full-node --clef-signer-enable --clef-signer-endpoint /var/lib/bee-clef/clef.ipc --swap-deployment-gas-price 16750000000400 --cache-capacity 80000000 --password-file /root/.bee-password-file  > /root/bee-start-info.log 2>&1 &
         fi
     sleep 60s
 done