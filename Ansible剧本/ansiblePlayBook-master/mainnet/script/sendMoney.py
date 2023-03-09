# coding=utf-8
##### 发小程序收益

import os,sys
import time
import argparse
import re,json
import urllib.request
import urllib.parse
import argparse

if __name__ == '__main__':
  ######################################
  withdrawFile = "withdrawReq.txt"
  fromWallt = "f3vvpc6b5mr5jvs3z3v7i5qkdlhujwrxavybrcrcdxxelef37jctqf7kb7cy7xyxtw5hqusan4qxncsst6f6pa"
  ######################################

  cmd = """grep -v '#' --text %s """%(withdrawFile)
  requestList = os.popen(cmd).read().rstrip().split("\n")
  for i in requestList:
    account, amount = i.split("\t")
    cmd = """~/bin/lotus send --from %s %s %s """%(fromWallt,account,amount)
    msg = os.popen(cmd).read().rstrip().split("\n")[0]
    print(cmd,msg)