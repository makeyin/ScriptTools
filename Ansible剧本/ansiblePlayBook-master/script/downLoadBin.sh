#!/bin/bash
num=0
MaxNum=5
url=$1
rm -f  "/tmp/lotus.tar"
while [[ $num -le $MaxNum ]]
do
    curl  --retry 3 --output "/tmp/lotus.tar"   $url
    if [ -e /tmp/lotus.tar ]
    then
        echo "Download success from $url"
        break
    else
        echo "Download fail, need retry $num"
        curl  --retry 3 --output "/tmp/lotus.tar"   $url
    fi
    let num+=1
 done