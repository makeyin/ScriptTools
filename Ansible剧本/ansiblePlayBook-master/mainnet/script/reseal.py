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
  cmd = """cat only_3.txt | awk '{print $1}' """
  secIDList = os.popen(cmd).read().rstrip().split("\n")
  secNum = len(secIDList)

  cmd = """cat availabe_slave | awk '{print $1}' """
  slaveIDList = os.popen(cmd).read().rstrip().split("\n")
  slaveNum = len(slaveIDList)

  ### every slave should do n sectors
  n = int((secNum + 0.0)/slaveNum) + 1

  for i in range(0,secNum):
    slaveIdx = i%slaveNum
    #print("Sector ID: %s sent to Slave ID: %s"%(secIDList[i],slaveIDList[slaveIdx]))
    cmd2 = """~/bin/lotus-power reseal sectors --target-peer %s --sector-ids %s --really-do-it"""%(slaveIDList[slaveIdx],secIDList[i])
    print(cmd2)
    os.popen(cmd2).read().rstrip()