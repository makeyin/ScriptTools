#!/bin/bash
Check=`ps -ef|grep bin/lotus|grep -v grep|grep devnet|wc -l`
if [ $Check -ge 2 ];then
        echo 'lotus is runing......'
else
        echo 'lotus not runing.....'
        exit 12
fi
#
#Msg=`~/bin/lotus mpool stat --local|tail -n1`
Msg=`~/bin/lotus mpool stat --local|tail -n1|awk  '{print $3,$5,$7}'|awk -F',' '{print $1,$2,$3}'|sed 's#[[:space:]] #-#g'`
#fil
Info=`~/bin/lotus-miner info`
MinerID=`echo "${Info}" |grep Miner:|awk '{print $2}'`
Balance=`echo "${Info}"|grep 'Worker Balance:' |awk '{print $3}'|awk -F'.' '{print $1}'`
Init=`echo "${Info}"|grep InitialPledgeRequirement: |awk '{print $2}'|awk -F'.' '{print $1}'`

Avai=`echo "${Info}"|grep Available: |awk '{print $2}'|awk -F'.' '{print $1}'`

#lotus info --- power
Power=`echo "${Info}"|grep 'Byte Power:'|awk '{print $3}'`

Faulty=`echo "${Info}"|grep 'Proving:' |awk '{print $4}'|awk -F'(' '{print $2}'`

#echo "$Balance, $Init, $Avai, $Power, $Faulty"

#sectors
Sectors=`curl -s 127.0.0.1:19402/metrics|grep SectorState|grep -v "#"`
#Committing:
Committing=`echo "${Sectors}"|grep SectorState|grep -v "#"|grep 'SectorStateCommitting'|awk '{print $2}'`

#SectorStateWaitSeed:
WaitSeed=`echo "${Sectors}"|grep SectorState|grep -v "#"|grep 'SectorStateWaitSeed'|awk '{print $2}'`
#SectorStateCommitFailed:
CommitFailed=`echo "${Sectors}"|grep SectorState|grep -v "#"|grep 'SectorStateCommitFailed'|awk '{print $2}'`

#peers
Peers=`~/bin/lotus net peers|wc -l`
#echo "$WaitSeed,$Committing,$CommitFailed"
#chain list
ChainDate=`~/bin/lotus chain list|tail -1|awk '{print $2,$3,$4}'|awk -F'(' '{print $2}'|awk -F')' '{print $1}'|sed 's#[[:space:]]#-#g'`
ChainHeight=`~/bin/lotus chain list|tail -1|awk '{print $1}'|awk -F':' '{print $1}'`

CurrentDate=`date '+%Y-%m-%d-%H:%M:%S'`
Hostinfo=`hostname`
Deal=`curl -g -i -X GET  "https://api.spacerace.filecoin.io/api/miner?take=50&search=${MinerID}&all=true"|grep items|jq '.items[0].deal_success_rate_store'`
LotusJson=`jq -n -M --arg minerid ${MinerID} --arg hostinfo ${Hostinfo} --arg lotusnum ${Check} --arg msgsum ${Msg} --arg balance ${Balance} --arg init ${Init} --arg avai ${Avai} --arg power ${Power} --arg faulty ${Faulty} --arg commiting ${Committing} --arg waitseed ${WaitSeed} --arg commitfailed ${CommitFailed} --arg peers ${Peers} --arg chaindate ${ChainDate} --arg chainheight ${ChainHeight} --arg currentdate ${CurrentDate} --arg deal ${Deal} '{"lotusnum":$lotusnum,"msgsum":$msgsum,"balance": $balance,"init":$init,"avai":$avai,"power":$power,"faulty":$faulty,"commiting":$commiting,"waitseed":$waitseed,"commitfailed":$commitfailed,"peers":$peers,"chaindate":$chaindate,"chainheight":$chainheight,"currentdate",$currentdate,"hostinfo":$hostinfo,"dealrate":$deal,"minerid",$minerid}'`
echo "$LotusJson"
curl -H "Accept: application/json" -H "Content-type: application/json" -X POST -d "${LotusJson}"  http://212.64.70.31:8000/host