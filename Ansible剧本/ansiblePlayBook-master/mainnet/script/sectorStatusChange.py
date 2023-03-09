# coding=utf-8
##### ./lotus-power sectors stat --state PreCommitFailed > PreCommitFailed.txt
##### 运行命令: python3 checkSlavePeers.py --warn=True
##### crontab任务设置： */5 * * * * cd /home/devnet;python3 checkMasterStatus.py --warn=True >> checkSlavePeers.log
import os,sys
import time
import argparse
import re,json
import urllib.request
import urllib.parse
import argparse

if __name__ == '__main__':
  onchainNum = 50
  sleepSec = 60

  cmd = """cat PreSealed.txt | awk '{print $1}' """
  secIDList = os.popen(cmd).read().rstrip().split("\n")
  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### Start to change sector status, total number is ",len(secIDList))
  ### 每次释放个数为onchainNum, 释放完一轮sleep的时间间隔是sleepSec
  for i in range(0,len(secIDList),onchainNum):
    secL=secIDList[i:i+onchainNum]
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to change %s sectors: %s"%(onchainNum, secL))
    for secId in secL:
      cmd2 = """/home/devnet/bin/lotus-power sectors update-state --really-do-it %s PreCommitWait"""%secId
      os.popen(cmd2).read().rstrip()
    time.sleep(sleepSec)