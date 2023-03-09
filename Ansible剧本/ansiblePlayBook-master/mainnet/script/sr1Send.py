# coding=utf-8
##### 发SR1收益
import os,sys
import time
import argparse
import re,json
import urllib.request
import urllib.parse
import argparse

if __name__ == '__main__':
  ######################################
  withdrawFile = "reqSR1.txt"
  minerInfoDict={
    "t03517":["/home/devnet/bin/lotus msig propose --from f3w75ipu5cx3dfwpknzjwdmry2ohn6ih2t76anzqbweyvh2jwc2rblysfwfmizrpm6au565wudeembwzfo2x2a f2qo537ygvvdn3f6o2y32zeuhzt5b42raedraue4a"],
    "t03269":["/home/devnet/bin/lotus msig propose --from f3w2wayb7gzcza2dfwm7vqwmcbzhofdbifguoewnhskz3duxzyov65wr3ljs45vmozcyvmylpf35fjmxoycvdq f2qxtz3hf4otnv3qlu2zgus472m47ckefduoytmfi"],
    "t016297":["/home/devnet/bin/lotus msig propose --from f3wogbakvnvrobfunblo7fwkcwkonho5fxio76kh5x7zhdxxeyr7yr3xgjjppxgwgcnxwumokpipbs5olcymaq f2ekaawzuu43vyaeovdggx4ymrdktqr7oyzffinjq"],
    "t03365":["/home/devnet/bin/lotus msig propose --from f3wg54mu4llwlzau4ieve3jart6tpr64lcheaybbkxvu6kgrcbme5fu6dlibu6363pblj7ep2oun4fjw4uvsoq f2vqgzzurwrtjbhq6fuexu67utefvdwwuy256myta"],
    "t015737":["/home/devnet/bin/lotus msig propose --from f3wayncyyykwb55hn7mpk5cizgxnrrpjkfex6kcj5rgiyyfpil4bp2j2fz4iwqrol77436nhsn2qtcejlumm3a f2cjeqqy36d3ai5ocbn6olc2zw3sv5hco4n3rgnpy"]
  }
  ######################################

  cmd = """grep -v '#' --text %s """%(withdrawFile)
  requestList = os.popen(cmd).read().rstrip().split("\n")
  for i in requestList:
    minerID, cusWallet, cusAmount, ourWallet, ourAmount = i.split("\t")

    cusAmount = cusAmount.rstrip()
    cmd1 = """%s %s %s """%(minerInfoDict[minerID][0],cusWallet,cusAmount)
    msg1 = os.popen(cmd1).read().rstrip()
    print(cmd1,msg1)

    ourAmount = ourAmount.rstrip()
    cmd2 = """%s %s %s """%(minerInfoDict[minerID][0],ourWallet,ourAmount)
    msg2 = os.popen(cmd2).read().rstrip()
    print(cmd2,msg2)