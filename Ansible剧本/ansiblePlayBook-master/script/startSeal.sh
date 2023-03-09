#!/bin/bash
# setsid ~/startSeal.sh > ~/startSeal.out 2>&1 &
mkdir -p ./sealed
rm -rf ./sealed/*
rm -rf ./cache
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null

export RUST_LOG=info;
export SECTOR_SIZE="1G";
export VDE_SWITCH=true;
export PRECOMMIT_COUNT=6;
export COMMIT_COUNT=3;
export TOTAL_TASKS=10000;
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed

export RUST_LOG=info
export SECTOR_SIZE="1G"
export VDE_SWITCH=true
export PRECOMMIT_COUNT=4
export COMMIT_COUNT=4
export TOTAL_TASKS=10000
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed

export RUST_LOG=info
export SECTOR_SIZE="1G"
export VDE_SWITCH=true
export PRECOMMIT_COUNT=2
export COMMIT_COUNT=2
export TOTAL_TASKS=10000
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed

export RUST_LOG=info
export SECTOR_SIZE="1G"
export VDE_SWITCH=true
export PRECOMMIT_COUNT=1
export COMMIT_COUNT=1
export TOTAL_TASKS=10000
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed

export RUST_LOG=info
export SECTOR_SIZE="256M"
export VDE_SWITCH=true
export PRECOMMIT_COUNT=8
export COMMIT_COUNT=8
export TOTAL_TASKS=10000
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed

export RUST_LOG=info
export SECTOR_SIZE="256M"
export VDE_SWITCH=true
export PRECOMMIT_COUNT=4
export COMMIT_COUNT=4
export TOTAL_TASKS=10000
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed

export RUST_LOG=info
export SECTOR_SIZE="256M"
export VDE_SWITCH=true
export PRECOMMIT_COUNT=2
export COMMIT_COUNT=2
export TOTAL_TASKS=10000
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to start seal bin, param is $PRECOMMIT_COUNT $COMMIT_COUNT $SECTOR_SIZE" 
setsid ~/seal > ~/seal.$SECTOR_SIZE.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`.out 2>&1 &
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to sleep 6h..." 
sleep 6h
echo `date +'%Y-%m-%d %H:%M:%S'` "end sleep 6h..." 
echo `date +'%Y-%m-%d %H:%M:%S'` "begin to kill seal process" 
kill -9 `ps -u $USER -f | grep seal | grep -v grep | grep -v view_lotus.sh| awk '{print $2}'` 2> /dev/null
mv ~/sealed ~/sealed.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mv ~/cache ~/cache.param-$PRECOMMIT_COUNT.$COMMIT_COUNT.`date +"%m%d%H%M"`
mkdir -p ./sealed