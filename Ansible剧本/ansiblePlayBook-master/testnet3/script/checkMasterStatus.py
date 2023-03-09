# coding=utf-8
##### 用来统计master节点的slave是否掉了，需要有一个全量的slave文件作为参考
##### 运行命令: python3 checkSlavePeers.py --warn=True
##### crontab任务设置： */5 * * * * cd /home/devnet;python3 checkMasterStatus.py --warn=True >> checkSlavePeers.log
import os,sys
import datetime,time
import argparse
import re
import urllib.request
import urllib.parse

def sendJianzhouMessage(phoneNumber,text):
    msgUrl = "http://www.jianzhou.sh.cn/JianzhouSMSWSServer/http/sendBatchMessage"
    account = "sdk_tianru"
    password = "7e9b673f499c986357db1e095da71be3"
    destmobile = phoneNumber
    msgText = "【天茹科技】" + text
    #msgHeader = {'Authorization':"APPCODE " + appcode}
    msgData = {'account':account,'password':password,'destmobile':destmobile,'msgText':msgText}

    data=urllib.parse.urlencode(msgData)
    data = data.encode('ascii')
    req = urllib.request.Request(msgUrl,data)
    res = urllib.request.urlopen(req)
    page = res.read().decode('utf-8')
    print(page)

def sendWarnMsg(phoneList,errorMsg):
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Need send out warning to : ",phoneList)
    for phone in phoneList:
        sendJianzhouMessage(phone,errorMsg)
        time.sleep( 2 )

def getSlaveFile(fileName):
    import os
    slaveList = []
    cmd = """grep -E '^192|^36' --text %s"""%(fileName)
    slaveList = os.popen(cmd).read().rstrip().split("\n")
    time.sleep(2)
    #去除空格和tab
    slaveListC = [''.join([slave.strip()]) for slave in slaveList]
    return slaveListC

def getSlavePeersFile(fileName):
    import os
    slaveList = []
    cmd = """grep -v '#' --text %s | cut -d ' ' -f 1"""%(fileName)
    slaveIPList = os.popen(cmd).read().rstrip().split("\n")
    cmd = """grep -v '#' --text %s | cut -d ' ' -f 2"""%(fileName)
    slavePeerIDList = os.popen(cmd).read().rstrip().split("\n")
    cmd = """grep -v '#' --text %s | cut -d ' ' -f 3"""%(fileName)
    posterPeerIDList = os.popen(cmd).read().rstrip().split("\n")
    time.sleep(2)
    #去除空格和tab
    slaveIPList_ = [''.join([slave.strip()]) for slave in slaveIPList]
    slavePeerIDList_ = [''.join([slave.strip()]) for slave in slavePeerIDList]
    posterPeerIDList_ = [''.join([slave.strip()]) for slave in posterPeerIDList]
    return slaveIPList_,slavePeerIDList_,posterPeerIDList_

def printList(hostList):
    for i in hostList:
        print(i)

def printPeerIPList(lostList,peerList,ipList):
    #打印ip和peerID
    if(lostList!=[""]):
        for i in lostList:
            idx = peerList.index(i)
            print(i,ipList[idx])

def redeemRewards():
    get_rewards_cmd ="~/bin/lotus-storage-miner rewards redeem"
    os.popen(get_rewards_cmd).read().rstrip()

def dealLostSlave():
    if(allSlavePeerIDList==[""]):
        print("丢失的slave的个数: ","未提供应连接的slave peer ID列表")
        return
    lostSlaveList=list(set(allSlavePeerIDList).difference(set(actualSlavePeersList))) # b中有而a中没有的
    print("丢失的slave的个数: ",len(lostSlaveList))
    printPeerIPList(lostSlaveList,allSlavePeerIDList,allSlaveIPList)

def dealLostPoster():
    if(allPosterPeerIDList==[""]):
        print("丢失的poster的个数: ","未提供应连接的poster peer ID列表")
        return
    lostPosterList=list(set(allPosterPeerIDList).difference(set(actualSlavePeersList))) # b中有而a中没有的
    print("丢失的poster的个数: ",len(lostPosterList))
    printPeerIPList(lostPosterList,allPosterPeerIDList,allSlaveIPList)

if __name__ == '__main__':
  ##########################################################
  host_file="slave_host_file"   #记录了slave的host
  phoneNumberList =["15618799939"]
  hostname="wx90"
  usePeerID=True
  #是否发送报警短信
  import argparse
  parser = argparse.ArgumentParser(description='manual to this script')
  parser.add_argument('--warn', default=False, type=bool)
  args = parser.parse_args()
  sendWarning=args.warn
  ##########################################################
  
  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### Start to check master status")
  ###第1步：redeem 余额到钱包地址
  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to send redeem msg...")
  #redeemRewards()

  ###第2步：检查master与slave和poster的连接
  print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check slave and poster peers connection...")
  allSlaveIPList,allSlavePeerIDList,allPosterPeerIDList=[],[],[]
  if(usePeerID):
        ### master实际连上的slave
        actualSlavePeersList = os.popen("~/bin/lotus-storage-miner net peers | awk -F':' '{print $1}' | awk -F'{' '{print $2}'").read().rstrip().split("\n")
        ### 真实部署的slave
        allSlaveIPList,allSlavePeerIDList,allPosterPeerIDList = getSlavePeersFile(host_file)
        print("master实际连上的Peers个数",len(actualSlavePeersList))
        print("master应有slave个数: ",len(allSlaveIPList))
        dealLostSlave()
        dealLostPoster()
  else:
        ### master实际连上的slave
        slavePeersList = os.popen("~/bin/lotus-storage-miner net peers|grep 8475 | awk -F'ip4/' '{print $2}' | awk -F'/' '{print $1}'").read().rstrip().split("\n")
        posterPeersList = os.popen("~/bin/lotus-storage-miner net peers|grep 9475 | awk -F'ip4/' '{print $2}' | awk -F'/' '{print $1}'").read().rstrip().split("\n")
        ### 真实部署的slave
        allSlaveList = getSlaveFile(host_file)
        print("master应有slave个数: ",len(allSlaveList))
        #print("\n")
        lostSlaveList=list(set(allSlaveList).difference(set(slavePeersList))) # b中有而a中没有的
        lostPosterList=list(set(allSlaveList).difference(set(posterPeersList))) # b中有而a中没有的
        print("丢失的slave的个数: ",len(lostSlaveList))
        printList(lostSlaveList)
        #print("\n")
        print("丢失的poster的个数: ",len(lostPosterList))
        printList(lostPosterList)

  ###第3步：检查master的链是否落后
  print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check master block chain height...")
  chainHeadTimeStamp=os.popen("~/bin/lotus chain head | head -1 | xargs -L1 ~/bin/lotus chain getblock | grep Timestamp|awk -F':' '{print $2}'").read().rstrip().split("\n")[0].split(",")[0]
  #print("Timestamp: ",chainHeadTimeStamp)
  import time
  now_time = time.time()
  secDelta = now_time - int(chainHeadTimeStamp)
  print("本地区块head的时间戳与当前时间的时间差:",secDelta)

  ###第4步：发送报警短信
  if(sendWarning):
      if(secDelta > 240):
          print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"block is lagging behind, send warning to: ",phoneNumberList)
          sendWarnMsg(phoneNumberList,"%s block is lagging behind"%hostname)
      if(len(lostPosterList)>0):
          print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"lost poster peers, send warning to: ",phoneNumberList)
          sendWarnMsg(phoneNumberList,"%s lost %s poster peers"%(hostname,len(lostPosterList)))
          #sendWarnMsg(phoneNumberList,"%s lost %s poster peers: %s"%(hostname,len(lostPosterList),lostPosterList))