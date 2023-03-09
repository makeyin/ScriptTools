#!/bin/bash
# 生成两个文件,一个是钱包地址,一个是钱包地址与key的对应关系

walletFile='/root/wallet.txt'

#mv ${walletFile} ${walletFile}.`date +"%m%d%H%M"`

for ((i=1; i<=400; i ++))
do
  wallet=`/root/lotus wallet new bls`
  echo $wallet >> $walletFile
done

keyFile='/root/key.txt'
cat $walletFile | while read w
do
  k=`~/bin/lotus wallet export $w`
  echo "$w $k" >> $keyFile
done