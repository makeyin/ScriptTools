#!/bin/bash
export FULLNODE_API_INFO=`grep FullNodeToken  ~/.lotusminer/config.toml|awk -F '\"' '{print $2}'`

minerID=$(grep provider ~/log/`ls -lt ~/log | awk '{print \$NF}' | grep lotus-power | head -1` | head -1 | awk  -F'"' '{print $4}')
sleep 10
echo "---------------------------------------  MinerID:${minerID}  --------------------------------------------------------"
stateMachine=`curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#" | grep -v " 0" | awk -F "State" '{print \$2}' | awk '{printf"%s ",\$0}'`
message=`~/bin/lotus mpool stat --local | awk -F "Nonce" '{print \$2}' | head -1`
sleep 10
bafflePlate=`grep "EnableManualPreCommitOnChain"  ~/.lotusminer/config.toml|awk -F "=" '{print \$2}'`
MaxSealTotal=`grep "MaxSealTotal" .lotusminer/config.toml |awk -F "=" '{print \$2}'`
echo 各阶段状态数:${stateMachine}
echo 消息量:${message}
echo 是否开启挡板:${bafflePlate}  MaxSealTotal:${MaxSealTotal}



export FULLNODE_API_INFO=`grep FullNodeToken  ~/.lotuswindow/config.toml|awk -F '\"' '{print $2}'`
~/bin/lotus-window sector query > query.txt
sleep 60
AllSector=sed -n '$p' query.txt |awk '{print $2}'
isuploads=sed -n '$p' query.txt |awk '{print $4}'
UploadSlave=grep "isUpload: false" query.txt  | wc -l
isFinish=grep "isFinish:false" query.txt  | wc -l
echo AllSector:${AllSector}
echo isuploads:${isuploads}
echo UploadSlave:${UploadSlave}
echo isFinish:${isFinish}



  export=os.popen("~/.lotuswinning/config.toml|awk -F '\"' '{print $2}'").read().rstrip()
  print("FULLNODE_API_INFO="+export)
