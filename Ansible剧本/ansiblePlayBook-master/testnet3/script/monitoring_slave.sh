#!/bin/bash
slaveFnum=`grep "lotus-slave:0" ~/log/filGuard.out |wc -l`
posterFnum=`grep "lotus-poster:0" ~/log/filGuard.out |wc -l`
lotusNum=`ps -ef | grep -w "lotus-slave-miner" | grep -v grep |wc -l`
if [ $lotusNum = 0 ]; then
        pre1ing=999
        pre1count=999
        pre1quene=999
        pre2ing=999
        pre2quene=999
else
        Comm=`~/bin/lotus-slave-miner info`
        pre1ing=`echo "${Comm}" |grep "PreCommit1" |awk '{ print $2}'`
        pre1count=`echo "${Comm}" |grep "PreCommit1" |awk '{ print $4}'`
        pre1quene=`echo "${Comm}" |grep "PreCommit1" |awk '{ print $5}'|tr -cd "[0-9]"`
        pre2ing=`echo "${Comm}" |grep "PreCommit2" |awk '{ print $2}'|tr -cd "[0-9]"`
        pre2quene=`echo "${Comm}" |grep "PreCommit2" |awk '{ print $5}'|tr -cd "[0-9]"`
fi
echo pre1ing $pre1ing >/var/run/prometheus/pnet.prom
echo pre1count $pre1count >>/var/run/prometheus/pnet.prom
echo pre1quene $pre1quene >>/var/run/prometheus/pnet.prom
echo pre2ing $pre2ing >>/var/run/prometheus/pnet.prom
echo pre2quene  $pre2quene >>/var/run/prometheus/pnet.prom
echo slaveFnum   $slaveFnum >>/var/run/prometheus/pnet.prom
echo posterFnum  $posterFnum >>/var/run/prometheus/pnet.prom