##### 用来统计master节点的slave是否掉了，需要有一个全量的slave文件作为参考
import os,sys
import datetime,time
import argparse

def getSlaveFile(fileName):
    import os
    slaveList = []
    cmd = """grep -E '^192|^36' --text %s"""%(fileName)
    slaveList = os.popen(cmd).read().rstrip().split("\n")
    time.sleep(2)
    return slaveList

def printList(hostList):
    for i in hostList:
        print(i)

if __name__ == '__main__':
  host_file="host_file"
  slavePeersList = os.popen("~/bin/lotus-storage-miner net peers|grep 8000 | awk -F'ip4/' '{print $2}' | awk -F'/' '{print $1}'").read().rstrip().split("\n")
  posterPeersList = os.popen("~/bin/lotus-storage-miner net peers|grep 9000 | awk -F'ip4/' '{print $2}' | awk -F'/' '{print $1}'").read().rstrip().split("\n")
  #print(slavePeers)
  #print(posterPeers)
  allSlaveList = getSlaveFile(host_file)
  print("master应有slave个数: ",len(allSlaveList))
  print("\n")
  lostSlaveList=list(set(allSlaveList).difference(set(slavePeersList))) # b中有而a中没有的
  lostPosterList=list(set(allSlaveList).difference(set(posterPeersList))) # b中有而a中没有的
  print("丢失的slave的个数: ",len(lostSlaveList))
  printList(lostSlaveList)
  print("\n")
  print("丢失的poster的个数: ",len(lostPosterList))
  printList(lostPosterList)
  