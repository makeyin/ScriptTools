# coding=utf-8
##### ./lotus-miner sectors stat --state PreSealed > pre.txt
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
  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### Start to change sector status")

  import os
  cmd = """grep PreCommitting 4w_host| awk '{print $1}' """
  secIDList = os.popen(cmd).read().rstrip().split("\n")
  print("failed sector length is ",len(secIDList))
  ### 每1秒钟释放1个
  for i in range(0,len(secIDList),20000):
    secL=secIDList[i:i+20000]
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to change 10 sectors: %s"%secL)
    for secId in secL:
      cmd2 = """/home/devnet/bin/lotus-miner sectors update-state --really-do-it %s PreCommitWait"""%secId
      os.popen(cmd2).read().rstrip()
    time.sleep(1600)