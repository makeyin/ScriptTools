#!/bin/bash
######### ./del.sh t02600 deletePreCommitFailedv
minerid=*
function deleteProving(){
    for line in `~/bin/lotus-slave-miner sectors list |grep Proving |awk -F ":" '{print $1}'`
    do
         echo -e "\033[41;37m 要删除的sector:$line的文件 \033[0m"
         echo  `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         for line1 in `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         do
                echo $line1
                rm -f -- `ls -l ~/.lotusslave/cache/s-$minerid-$line/$line1`
         done
    done
}

function deletePreCommit1(){
    for line in `~/bin/lotus-slave-miner sectors list |grep PreCommit1 |awk -F ":" '{print $1}'`
    do
         echo -e "\033[41;37m 要删除的sector:$line的文件 \033[0m"
         echo  `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         for line1 in `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         do
                echo $line1
                rm -f -- `ls -l ~/.lotusslave/cache/s-$minerid-$line/$line1`
         done
    done
}

function deleteWaitSeed(){
    for line in `~/bin/lotus-slave-miner sectors list |grep WaitSeed |awk -F ":" '{print $1}'`
    do
         echo -e "\033[41;37m 要删除的WaitSeed sector:$line的文件 \033[0m"
         echo  `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         for line1 in `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         do
                echo $line1
                rm -f -- `ls -l ~/.lotusslave/cache/s-$minerid-$line/$line1`
         done
    done
}

function deletePreCommitFailed(){
    for line in `~/bin/lotus-slave-miner sectors list |grep -E "PreCommitFailed|CommitFailed" |awk -F ":" '{print $1}'`
    do
         echo -e "\033[41;37m 要删除的sector:$line的文件 \033[0m"
         echo  `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         for line1 in `ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         do
                echo $line1
                rm -f -- `ls -l ~/.lotusslave/cache/s-$minerid-$line/$line1`
         done
                rm -f -- `ls -l ~/.lotusslave/sealed/s-$minerid-$line`
    done
}

function check(){
    for line in `~/bin/lotus-slave-miner sectors list |grep -E "PreCommitFailed|CommitFailed|Proving"  |awk -F ":" '{print $1}'`
    do
         echo -e "\033[41;37m 要检查的sector:$line的文件 \033[0m"
         otherFile=`ls -l ~/.lotusslave/cache/s-$minerid-$line|awk '{print $9}'|grep -v -E "(p_aux|t_aux|sc-02-data-tree-d.dat|tree-r)"`
         #echo  $otherFile
         if [[ ("${otherFile}" -lt "1") ]];then
                 echo "无需删除"
         else
                 echo "delete"
         fi
    done
}

case "$1" in
deletePreCommit1)
       deletePreCommit1
       ;;
deleteProving)
       deleteProving
       ;;
deleteWaitSeed)
       deleteWaitSeed
       ;;
check)
       check
       ;;
delPreCF)
       deleteProving
       deletePreCommitFailed
       rm -rf ~/.lotusslave.0*
       rm -rf ~/.lotusstorage.0*
       rm -rf ~/.lotus.0*
       ;;
*)
esac