#!/bin/bash
if [ -n "`ps aux | grep seal | grep -v grep`" ]
then
    echo `date +'%Y-%m-%d %H:%M:%S'` "Kill old seal process..."
    kill -9 `ps -u $USER -f | grep seal | grep -v grep | awk '{print $2}'` 2> /dev/null
    sleep 15
fi

export RUST_BACKTRACE=full
export RUST_LOG=info
export TOTAL_TASKS=15
export PRECOMMIT_COUNT=1
export COMMIT_COUNT=1  #1

export OPTION1=false
export OPTION2=true
export OPTION3=5
export OPTION4=false
export OPTION5=false
export OPTION6=0
export OPTION7=10500
export OPTION8=false
export OPTION9=1
export OPTION10=10

echo `date +'%Y-%m-%d %H:%M:%S'` "Begin to start seal process..."
setsid ./seal_safe > ./seal_safe.`date +"%m%d%H%M"`.out 2>&1 &

echo `date +'%Y-%m-%d %H:%M:%S'` "Seal Started!"
