# -*- coding:utf-8 -*-
##### 用来统计master节点的slave是否掉了，需要有一个全量的slave文件作为参考
##### 运行命令: python3 checkSlavePeers.py --warn=True
##### crontab任务设置： */5 * * * * cd /home/devnet;python3 checkMasterStatus.py --warn=True >> checkSlavePeers.log
import os,sys
import time
import argparse
import re,json
import urllib.request
import urllib.parse
import argparse

#### 默认的msgurl是钉钉的5PB报警群
def sendDingdingMessage(text,token="03f45c5da64da39d5222a78de0e2475d122f9c91e00a139ef0705729330c30d4"):
    msgurl = "https://oapi.dingtalk.com/robot/send?access_token=" + token
    header = {"Content-Type": "application/json","Charset": "UTF-8"}

    msgText = "Hi, 我是小蜜！" + text
    msgData = {"msgtype": "text","text": {"content": msgText }}
    #msgData = {"msgtype": "text","text": {"content": msgText }, "at": { "isAtAll": true }}
    sendData = json.dumps(msgData)
    sendData = sendData.encode("utf-8")

    #发送�����求
    request = urllib.request.Request(url=msgurl, data=sendData, headers=header)
    # 将请求发回的数据构建成为文件格式
    opener = urllib.request.urlopen(request)
    page = opener.read().decode('utf-8')
    print(page)

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

def withdrawRewards(amount):
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to send redeem msg...")
    get_rewards_cmd ="~/bin/lotus-power actor withdraw %s"%amount
    os.popen(get_rewards_cmd).read().rstrip()

def checkPeersConnection():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check slave and poster peers connection...")
    allSlaveIPList,allSlavePeerIDList,allPosterPeerIDList=[],[],[]
    ### master实际连上的slave
    actualSlavePeersList = os.popen("~/bin/lotus-power net peers | awk -F',' '{print $1}' ").read().rstrip().split("\n")
    ### 真实部署的slave
    allSlaveIPList,allSlavePeerIDList,allPosterPeerIDList = getSlavePeersFile(host_file)
    print("master实际连上的Peers个数",len(actualSlavePeersList))
    print("master应有slave个数: ",len(allSlaveIPList))
    #######dealLostSlave()
    if(allSlavePeerIDList==[""]):
        print("丢失的slave的个数: ","未提供应连接的slave peer ID列表")
    else:
        lostSlaveList=list(set(allSlavePeerIDList).difference(set(actualSlavePeersList))) # b中有而a中没有的
        print("丢失的slave的个数: ",len(lostSlaveList))
        printPeerIPList(lostSlaveList,allSlavePeerIDList,allSlaveIPList)
    return lostSlaveList

def checkChainList():
    import time
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check master block chain height...")
    chainHeadTimeStamp=os.popen("~/bin/lotus chain head | head -1 | xargs -L1 ~/bin/lotus chain getblock | grep Timestamp|awk -F':' '{print $2}'").read().rstrip().split("\n")[0].split(",")[0]
    #print("Timestamp: ",chainHeadTimeStamp)
    import time
    now_time = time.time()
    secDelta = now_time - int(chainHeadTimeStamp)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Local chain head timestamp - Local timestamp = ",int(secDelta))
    return secDelta

def checkMinerInfo():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check miner info...")
    minerInfo = os.popen("~/bin/lotus-power info").read().rstrip()

    reg2 = r'Available:  (.*)FIL'
    img_title2 = re.compile(reg2)
    res2 = re.findall(img_title2, minerInfo)
    #print(res2[0])
    minerAvailable = int(float(res2[0].strip()))
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Miner Available: %s"%minerAvailable)

    reg3 = r'Worker Balance: (.*)FIL'
    img_title3 = re.compile(reg3)
    res3 = re.findall(img_title3, minerInfo)
    #print(res3[0].strip())
    walletBalance = int(float(res3[0].strip()))
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Wallet Balance: %s"%walletBalance)

    reg4 = r'Miner: (.*)'
    img_title4 = re.compile(reg4)
    res4 = re.findall(img_title4, minerInfo)
    #print(res4[0].strip())
    minerNum = res4[0].strip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Miner: %s"%minerNum)

    reg5 = r'Actual Power: (.*) /'
    img_title5 = re.compile(reg5)
    res5 = re.findall(img_title5, minerInfo)
    #print(res4[0].strip())
    power = res5[0].strip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Actual Power: %s"%power)

    reg6 = r'iB(.*)Faulty,'
    img_title6 = re.compile(reg6)
    res6 = re.findall(img_title6, minerInfo)
    #print(res4[0].strip())
    fault = " ( 0.0 T "
    if(res6 != []):
      fault = res6[0].strip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Faulty: %s )"%fault)
    power = power + fault + " Faulty )"
    return walletBalance,minerAvailable,minerNum,power

def checkMpoolStat():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check mpool stat...")
    mpool = os.popen("~/bin/lotus mpool stat --local|tail -n1|awk  '{print $3,$5,$7}'|awk -F',' '{print $1,$2,$3}'|sed 's#[[:space:]] #,#g'").read().rstrip().split(",")
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Lotus mpool stat local: %s"%mpool)
    return mpool

def checkProcess():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check lotus-power process...")
    minerNum = int(os.popen("""ps -ef | grep "lotus-power run" | grep -v grep |wc -l""").read().rstrip())
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner num: ",minerNum)
    return minerNum

def checkSectorStatus():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check sector status...")
    sectorStr = os.popen(""" curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#"|grep -v ' 0' | sed 's/SectorState//g' """).read().rstrip()
    return sectorStr

def sendMoneyToMiner(minerNum,amount):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to send money...")
    mpool = os.popen("~/bin/lotus send %s %s"%(minerNum,amount)).read().rstrip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Send money done!")

def calSectorsStat(sectorsstat):
    secDict = {}
    if("PreCommit1" in sectorsstat):
      reg = r'PreCommit1 (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      secDict["PreCommit1"] = int(res[0].strip())

    if("PreSealed" in sectorsstat):
      reg = r'PreSealed (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      secDict["PreSealed"] = int(res[0].strip())
    
    if("PreCommitting" in sectorsstat):
      reg = r'PreCommitting (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      secDict["PreCommitting"] = int(res[0].strip())

    if("Committing" in sectorsstat):
      reg = r'Committing (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      if(res!=""):
        secDict["Committing"] = int(res[0].strip())

    if("SubmitCommit" in sectorsstat):
      reg = r'SubmitCommit (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      secDict["SubmitCommit"] = int(res[0].strip())

    if("CommitFailed" in sectorsstat):
      reg = r'CommitFailed (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      secDict["CommitFailed"] = int(res[0].strip())

    if("SealPreCommit1Failed" in sectorsstat):
      reg = r'SealPreCommit1Failed (.*)'
      img_title = re.compile(reg)
      res = re.findall(img_title, sectorsstat)
      secDict["SealPreCommit1Failed"] = int(res[0].strip())

    return secDict

def checkPostWallet():
    postwallet="";amount=""
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check wallet for post msg...")
    res = os.popen("~/bin/lotus-power actor control list --verbose | grep control-0 | awk '{print $3,$5}'").read().rstrip()
    postwallet, amount = res.split(" ")
    amount = amount.strip().split("m")[1]
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"post wallet: %s, balance: %s FIL"%(postwallet, amount))
    return postwallet, float(amount)

if __name__ == '__main__':
  ################################################################################################
  host_file="slave_host_file"   #记录了slave的host
  phoneNumberList =["15618799939"]
  hostname=os.popen("hostname").read().rstrip()

  parser = argparse.ArgumentParser(description='manual to this script')
  parser.add_argument('--warn', default=False, type=bool)
  args = parser.parse_args()
  sendWarning=args.warn   #是否发送报警短信
  walletBalanceMinimum = 200 ####设置wallet 余额最小是多少
  availableDifference = 300  ####设置miner available的余额需要比miner IPR大多少
  msgThreshold = 150  ### 消息池卡了多少条消息后就开始报警

  if(hostname == "server8"):
    hostname = "SAMuCang"

  defaultToken = "73adabba2fbb51025f897a8f2a9c4bd48b3e58df0cb7bb06696084a54a348959"   ##### 客户节点钉钉群的url
  if("1475" in hostname or "self" in hostname):
    defaultToken = "03f45c5da64da39d5222a78de0e2475d122f9c91e00a139ef0705729330c30d4"   ##### 1475节点钉钉群的url

  # minerID, precommit1_max_num, committing_max_num
  hostInfo={
    "self3.29":["f021547",3000,600],
    "self8.61":["f045756",2270,500],
    "self8.49":["f061051",2600,1000],
    "kwjsl-power":["f023882",1000,1000],
    "jiedi-power":["f030408",500,500],
    "xiongmao2-192-168-1-13":["f021961",1010,700],
    "saidao-power":["t023499",310,200],
    "xjcc-power":["t021536",1540,1500],
    "jiedi":["f030408",1000,1000],
    "xjgl-winning":["f022804",1540,1500],
    "shenyang-power":["f029665",1540,1500],
    "myay-192-168-10-173":["f033028",540,500]
  }

  ################################################################################################

  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### Start to check master status")

  ### 第1步：检查lotus-power进程  ##########################################################
  minerN = checkProcess()
  process_health = True
  if(minerN==0):
    process_health = False
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"lotus-power 进程数量异常: %s, send warning"%daemonN)
    #sendDingdingMessage("机器:%s 严重警告: lotus-power 进程挂了!!! lotus-power 进程数量: %s "%(hostname,daemonN,minerN))

  ### 第2步：检查master与slave的连接  ################################################
  # lostSlaveList = []
  # lostSlaveList = checkPeersConnection()
  # if(len(lostSlaveList)>0):
  #   print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"lotus-power lost slave peers, send warning")
    #sendDingdingMessage("机器:%s 严重警告: lost %s poster peers"%(hostname,len(lostPosterList)))

  warnSecDict={}
  if(minerN!=0):
    sectorsStat = "扇区状态:\n" + checkSectorStatus()
    warnSecDict = calSectorsStat(sectorsStat)

  Sector_preCommitting = True; 
  Sector_SubmitCommit = True; 
  Sector_PreSealed = True;
  Sector_PreCommit1=True;
  Sector_Committing=True;
  Sector_SealPreCommit1Failed=True;
  Sector_CommitFailed=True;
  if("PreSealed" in warnSecDict.keys() ):
    Sector_PreSealed=False
  if("PreCommitting" in warnSecDict.keys()):
    Sector_preCommitting=False
  if("SubmitCommit" in warnSecDict.keys()):
    Sector_SubmitCommit=False
  if("SealPreCommit1Failed" in warnSecDict.keys()):
    Sector_SealPreCommit1Failed=False
  if("CommitFailed" in warnSecDict.keys()):
    Sector_CommitFailed=False
  if("PreCommit1" in warnSecDict.keys() and warnSecDict["PreCommit1"] > hostInfo[hostname][1]):
    Sector_PreCommit1=False
  if("Committing" in warnSecDict.keys() and warnSecDict["Committing"] > hostInfo[hostname][2]):
    Sector_Committing=False

  report = "\n机器 %s 节点 %s 的报告: "%(hostname,hostInfo[hostname][0])
  if(process_health and Sector_preCommitting and Sector_SubmitCommit and Sector_PreSealed and Sector_PreCommit1 and Sector_Committing and Sector_SealPreCommit1Failed and Sector_CommitFailed):
    report += "\n目前lotus-power进程正常"
  else:
    if(not Sector_PreSealed):
      report += "\n提醒: 有PreSealed状态的扇区, 注意过期 "
    if(not Sector_preCommitting):
      report += "\n严重警告: 有preCommitting状态的扇区, 注意过期, 请尽快手动释放 "
    if(not Sector_SubmitCommit):
      report += "\n严重警告: 有SubmitCommit状态的扇区, 注意过期, 请尽快手动释放 "
    if(not Sector_SealPreCommit1Failed):
      report += "\n警告: 有SealPreCommit1Failed状态的扇区, 请尽快分析原因 "
    if(not Sector_CommitFailed):
      report += "\n严重警告: 有CommitFailed状态的扇区, 请尽快分析原因 "
    if(not Sector_PreCommit1):
      report += "\n警告: PreCommit1状态的扇区, 超过限定值 %s "%hostInfo[hostname][1]
    if(not Sector_Committing):
      report += "\n警告: Committing状态的扇区, 超过限定值 %s, 注意排查OSP状态 "%hostInfo[hostname][2]
  sendDingdingMessage(report + "\n\n" + sectorsStat + "\n",defaultToken)