#!/bin/bash
while true
do
        echo `date`
if [[ `~/bin/view_lotus.sh info |grep Sectors | grep Committing` == *Committing* ]];then
        Committing=`~/bin/view_lotus.sh info |grep Sectors |awk -F "Committing" '{print $2}'| awk -F " " '{print $1}'|sed 's/:/ /g'|sed 's/]/ /g'`
else
        Committing=0
fi
if [[ `~/bin/view_lotus.sh info |grep Sectors | grep PreCommitted` == *PreCommitted* ]];then
        PreCommitted=`~/bin/view_lotus.sh info |grep Sectors |awk -F "PreCommitted" '{print $2}'| awk -F " " '{print $1}'|sed 's/:/ /g'|sed 's/]/ /g'`
else
        PreCommitted=0
fi
if [[ `~/bin/view_lotus.sh info |grep Sectors | grep Proving` == *Proving* ]];then
        Proving=`~/bin/view_lotus.sh info |grep Sectors |awk -F "Proving" '{print $2}'| awk -F " " '{print $1}'|sed 's/:/ /g'`
else
        Proving=0
fi
if [[ `~/bin/view_lotus.sh info |grep Sectors | grep Total` == *Total* ]];then
        Total=`~/bin/view_lotus.sh info |grep Sectors |awk -F "Total" '{print $2}'| awk -F " " '{print $1}'|sed 's/:/ /g'|sed 's/]/ /g'`
else
        Total=0
fi
if [[ `~/bin/view_lotus.sh info |grep Sectors | grep Unsealed` == *Unsealed* ]];then
        Unsealed=`~/bin/view_lotus.sh info |grep Sectors |awk -F "Unsealed" '{print $2}'| awk -F " " '{print $1}'|sed 's/:/ /g'|sed 's/]/ /g'`
else
        Unsealed=0
fi
if [[ `~/bin/view_lotus.sh info |grep Sectors | grep PreCommitting` == *PreCommitting* ]];then
        PreCommitting=`~/bin/view_lotus.sh info |grep Sectors |awk -F "PreCommitting" '{print $2}'| awk -F " " '{print $1}'|sed 's/:/ /g'|sed 's/]/ /g'`
else
        PreCommitting=0
fi
if [[ `~/bin/lotus-slave-miner net listen` ==  *p2p* ]];then
        walletBal=0
else
        walletBal=`~/bin/lotus wallet balance`
fi
if [[ `~/bin/lotus-slave-miner net listen` ==  *p2p* ]];then
        pledge=0
else
        pledge=`~/bin/lotus-storage-miner state pledge-collateral`
fi
if [[ `~/bin/lotus-slave-miner net listen` ==  *p2p* ]];then
        chainHeight=0
else
        chainHeight=`~/bin/lotus chain list |tail -1|awk '{print $1}'|sed 's/:/ /g'`
fi
if [[ `~/bin/lotus-slave-miner net listen` ==  *p2p* ]];then
        postHeight=0
else
        if [[ `~/bin/view_lotus.sh info | grep Period` == *Not* ]];then
        postHeight=0
else
        postHeight=`~/bin/view_lotus.sh info |grep Period|awk -F "Period:" '{print $2}'|awk -F "," '{print $1}'`
fi
fi
if [[ `~/bin/lotus-slave-miner net listen` ==  *p2p* ]];then
        postTime=0
else
        if [[ `~/bin/view_lotus.sh info | grep Period` == *Not* ]];then
        postTime=0
else
        postTime=`~/bin/view_lotus.sh info |grep Period|awk -F "Period:" '{print $2}'|awk -F " " '{print $3}'`
fi
fi

echo Committing $Committing >~/log/prometheus/lotus.prom
echo PreCommitted $PreCommitted >>~/log/prometheus/lotus.prom
echo Proving $Proving >>~/log/prometheus/lotus.prom
echo Total $Total >>~/log/prometheus/lotus.prom
echo Unsealed $Unsealed >>~/log/prometheus/lotus.prom
echo PreCommitting $PreCommitting >>~/log/prometheus/lotus.prom
echo netPeers  `~/bin/lotus net peers |wc -l` >>~/log/prometheus/lotus.prom
echo walletBal $walletBal >>~/log/prometheus/lotus.prom
echo pledge $pledge >>~/log/prometheus/lotus.prom
echo AddPieceWorker `~/bin/view_lotus.sh info |grep AddPiece |awk '{print $4}'` >>~/log/prometheus/lotus.prom
echo AddpieceUser `~/bin/view_lotus.sh info |grep AddPiece |awk '{print $2}'` >>~/log/prometheus/lotus.prom
echo RemoteWorker `~/bin/view_lotus.sh info |grep Remote |awk '{print $4}'` >>~/log/prometheus/lotus.prom
echo RemoteUser `~/bin/view_lotus.sh info |grep Remote |awk '{print $2}'` >>~/log/prometheus/lotus.prom
echo PreCommitWorker `~/bin/view_lotus.sh info |grep PreCommit: |awk '{print $4}'` >>~/log/prometheus/lotus.prom
echo PreCommitUser `~/bin/view_lotus.sh info |grep PreCommit: |awk '{print $2}'` >>~/log/prometheus/lotus.prom
echo CommittingWorker `~/bin/view_lotus.sh info |grep Committing |awk '{print $4}'` >>~/log/prometheus/lotus.prom
echo CommittingUser `~/bin/view_lotus.sh info |grep Committing |awk '{print $2}'` >>~/log/prometheus/lotus.prom
echo ImportSealedSectorWorker `~/bin/view_lotus.sh info |grep ImportSealedSector |awk '{print $4}'` >>~/log/prometheus/lotus.prom
echo ImportSealedSectorUser `~/bin/view_lotus.sh info |grep ImportSealedSector |awk '{print $2}'` >>~/log/prometheus/lotus.prom
echo chainHeight $chainHeight  >>~/log/prometheus/lotus.prom
echo postHeight $postHeight  >>~/log/prometheus/lotus.prom
echo postTime $postTime >>~/log/prometheus/lotus.prom
sleep 2m
done