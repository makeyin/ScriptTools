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

def sendWarnTextMsg(phoneList,errorMsg):
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Need send out warning to : ",phoneList)
    for phone in phoneList:
        sendJianzhouMessage(phone,errorMsg)
        time.sleep( 2 )

#### 默认的msgurl是钉钉的5PB报警群
def sendDingdingMessage(text,token="03f45c5da64da39d5222a78de0e2475d122f9c91e00a139ef0705729330c30d4"):
    msgurl = "https://oapi.dingtalk.com/robot/send?access_token=" + token
    header = {"Content-Type": "application/json","Charset": "UTF-8"}

    msgText = "Hi, 我是小蜜！" + text
    msgData = {"msgtype": "text","text": {"content": msgText }}
    #msgData = {"msgtype": "text","text": {"content": msgText }, "at": { "isAtAll": true }}
    sendData = json.dumps(msgData)
    sendData = sendData.encode("utf-8")

    #发送请求
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
    get_rewards_cmd ="~/bin/lotus-miner actor withdraw %s"%amount
    os.popen(get_rewards_cmd).read().rstrip()

def checkPeersConnection():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check slave and poster peers connection...")
    allSlaveIPList,allSlavePeerIDList,allPosterPeerIDList=[],[],[]
    ### master实际连上的slave
    actualSlavePeersList = os.popen("~/bin/lotus-storage-miner net peers | awk -F':' '{print $1}' | awk -F'{' '{print $2}'").read().rstrip().split("\n")
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
    #######dealLostPoster()
    lostPosterList_ = []
    if(allPosterPeerIDList==[""]):
        print("丢失的poster个数: ","未提供应连接的poster peer ID列表")
    else:
        lostPosterList=list(set(allPosterPeerIDList).difference(set(actualSlavePeersList))) # b中有而a中没有的
        print("丢失的poster的个数: ",len(lostPosterList))
        printPeerIPList(lostPosterList,allPosterPeerIDList,allSlaveIPList)
    return lostPosterList_

def checkChainList():
    import time
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check master block chain height...")
    chainHeadTimeStamp=os.popen("~/bin/lotus chain head | head -1 | xargs -L1 ~/bin/lotus chain getblock | grep Timestamp|awk -F':' '{print $2}'").read().rstrip().split("\n")[0].split(",")[0]
    #print("Timestamp: ",chainHeadTimeStamp)
    import time
    now_time = time.time()
    secDelta = now_time - int(chainHeadTimeStamp)
    print("Local chain head timestamp - Local timestamp = ",secDelta)
    return secDelta

def checkMinerInfo():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check miner info...")
    minerInfo = os.popen("~/bin/lotus-miner info").read().rstrip()

    reg1 = r'InitialPledgeRequirement:  (.*)FIL'
    img_title = re.compile(reg1)
    res1 = re.findall(img_title, minerInfo)
    minerIPR = int(float(res1[0].strip()))
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Miner InitialPledgeRequirement: %s"%minerIPR)

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
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Faulty: %s"%fault)
    power = power + fault + " Faulty )"
    return walletBalance,minerAvailable,minerIPR,minerNum,power

def checkMpoolStat():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check mpool stat...")
    mpool = os.popen("~/bin/lotus mpool stat --local|tail -n1|awk  '{print $3,$5,$7}'|awk -F',' '{print $1,$2,$3}'|sed 's#[[:space:]] #,#g'").read().rstrip().split(",")
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Lotus mpool stat local: %s"%mpool)
    return mpool

def checkWpostStat():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check mpool stat...")
    mpool = os.popen("~/bin/lotus mpool stat | grep `~/bin/lotus wallet default`").read().rstrip()
    reg1 = r'InitialPledgeRequirement:  (.*)FIL'
    img_title = re.compile(reg1)
    res1 = re.findall(img_title, mpool)
    minerIPR = int(float(res1[0].strip()))
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Miner InitialPledgeRequirement: %s"%minerIPR)

def checkProcess():
    daemonNum=-1;minerNum=-1
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check lotus process...")
    daemonNum = int(os.popen("""ps -ef | grep "lotus daemon" | grep -v grep |wc -l""").read().rstrip())
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"daemon num: ",daemonNum)

    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check lotus-miner process...")
    minerNum = int(os.popen("""ps -ef | grep "lotus-miner run" | grep -v grep |wc -l""").read().rstrip())
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner num: ",minerNum)
    return daemonNum,minerNum

def checkSectorStatus():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check sector status...")
    sectorStr = os.popen(""" curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#"|grep -v ' 0' | sed 's/SectorState//g' """).read().rstrip()
    return sectorStr

def sendMoneyToMiner(minerNum,amount):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to send money...")
    mpool = os.popen("~/bin/lotus send %s %s"%(minerNum,amount)).read().rstrip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Send money done!")

def checkPostWallet():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check wallet for post msg...")
    res = os.popen("~/bin/lotus-miner actor control list --verbose | grep control-0 | awk '{print $3,$5}'").read().rstrip()
    postwallet, amount = res.split(" ")
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"post wallet: %s, balance: %s FIL"%(postwallet, amount))

if __name__ == '__main__':
  ################################################################################################
  host_file="slave_host_file"   #记录了slave的host
  phoneNumberList =["15618799939"]
  hostname=os.popen("hostname").read().rstrip()

  parser = argparse.ArgumentParser(description='manual to this script')
  parser.add_argument('--warn', default=False, type=bool)
  args = parser.parse_args()
  sendWarning=args.warn   #是否发送报警短信
  walletBalanceMinimum = 400 ####设置wallet 余额最小是多少
  availableDifference = 500  ####设置miner available的余额需要比miner IPR大多少
  msgThreshold = 150  ### 消息池卡了多少条消息后就开始报警
  
  if(hostname == "server8"):
    hostname = "SAMuCang"
  
  defaultToken = "73adabba2fbb51025f897a8f2a9c4bd48b3e58df0cb7bb06696084a54a348959"   ##### 5PB节点钉钉群的url
  if("1475" in hostname or "self" in hostname):
    defaultToken = "03f45c5da64da39d5222a78de0e2475d122f9c91e00a139ef0705729330c30d4"   ##### 1475节点钉钉群的url

  customerInfoDict={
    "wx82Tegong":["2e3aeb7166b92553e12a36f265e4816b6f85a3987edf212755d5cfe6732f7f37"],
    "XiniXJTeGong":["2e3aeb7166b92553e12a36f265e4816b6f85a3987edf212755d5cfe6732f7f37"],
    "wx83MK":["ec20961476e44f0d2f0d082d75056d60e40d5b725d7c565e59e7471d4b1a06aa"],
    "wx84Yotta":["0caf86bfb9c43abe848d8c0680e70dc253910df37e70f9827458536df7025d4f"],
    "wx85DieLian":["25aa0c5139f049d64f2acc42722277734ba6759b03d520be596a7255005e60ca"],
    "EuropeDieLian":["25aa0c5139f049d64f2acc42722277734ba6759b03d520be596a7255005e60ca"],
    "wx90GongLian":["2c3aa0a640a77da0955c624dcb3a1da4cd12e4b9d39446f8fc3c6a6cab50865d"],
    "nanmeiGonglian":["2c3aa0a640a77da0955c624dcb3a1da4cd12e4b9d39446f8fc3c6a6cab50865d"],
    "USAGonglian":["2c3aa0a640a77da0955c624dcb3a1da4cd12e4b9d39446f8fc3c6a6cab50865d"],
    "XiniKuangWuJie":["69b7aef854cc23f67ab97e7712d1e6e99467dc5d02576006e27433506278568d"],
    "SAKuangWuJie":["69b7aef854cc23f67ab97e7712d1e6e99467dc5d02576006e27433506278568d"],
    "XiniXingJiUnion":["811f66c1fb20b09b541b0ac2a526548fd8d6b70be6a3adb423a251f7282a893a"],
    "EuropeXJCC":["68d634eab83828f138041d16fcaeaca20f59026d45cd09b71b44d554491a5c0a"],
    "AfricaXJCC":["68d634eab83828f138041d16fcaeaca20f59026d45cd09b71b44d554491a5c0a"],
    "ShunRui":["0422a078fc9143879922b7bd4a9094b49c14f29c8ab38cee68e53c30339560f0"],
    "my132Anyi":["0422a078fc9143879922b7bd4a9094b49c14f29c8ab38cee68e53c30339560f0"]
  }
  
  ################################################################################################

  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### Start to check master status")

  ### 第1步：检查lotus 和 miner进程  ##########################################################
  daemonN,minerN = checkProcess()
  process_health = True
  if(daemonN!=-1):
    if(daemonN==0 or minerN==0):
      process_health = False
      print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"daemon 进程数量异常: %s, send warning"%daemonN)
      #sendDingdingMessage("机器:%s 严重警告: lotus 进程挂了!!! daemon 进程数量: %s. miner 进程数量: %s "%(hostname,daemonN,minerN))

  ### 第2步：检查master与slave和poster的连接  ################################################
  lostPosterList = []
  #lostPosterList = checkPeersConnection()
  if(len(lostPosterList)>0):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"lost poster peers, send warning")
    #sendDingdingMessage("机器:%s 严重警告: lost %s poster peers"%(hostname,len(lostPosterList)))

  ### 第3步：检查master的链是否落后  #########################################################
  secDelta = -1
  secDelta = checkChainList()
  chain_health = True
  if(secDelta > 300):
    chain_health = False
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"chain is lagging behind, send warning")
    #sendDingdingMessage("机器:%s 严重警告: 区块落后超过 %s 分钟"%(hostname,int(secDelta/60.0)))

  ### 第4步：检查master的钱包账户是否充足和扇区状态信息  #########################################################
  #lowWalletBalance, lowMinerAvailable, lessThanIPR = False # lessThanIPR: miner available less than InitialPledgeRequirement
  minerIPR=-1;minerAvailable=-1;walletBalance=-1
  wallet_health = True; available_diff_health = True
  minerNum = ""; sectorsStat=""; power="";powerStatus="";walletStatus=""
  postWallet="";postBalance=""
  ### miner进程存在时才可以检查miner信息
  if(minerN!=0):
    walletBalance,minerAvailable,minerIPR,minerNum,power = checkMinerInfo()
    
    sectorsStat = "扇区状态:\n" + checkSectorStatus()
    powerStatus = "当前算力: " + power
    walletStatus = "当前钱包余额: " + str(walletBalance) + ", 矿工余额: " + str(minerAvailable) + ", 抵押账户: " + str(minerIPR)
    postWallet,postBalance=checkPostWallet()

  ### wallet余额小于walletBalanceMinimum就报警
  if(walletBalance != -1 and walletBalance < walletBalanceMinimum):
    wallet_health = False
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"walletBalance less than %s, send warning"%walletBalanceMinimum)
    #sendDingdingMessage("机器:%s 警告: wallet钱包余额不足,请尽快接水龙头！当前余额为 %s"%(hostname,walletBalance))
    #### 缺钱了,发送报警信息到客户的钉钉群 ####
    ########################################
    sendDingdingMessage("警告: 节点%s的wallet钱包余额不足,请尽快接水龙头！当前余额为 %s"%(minerNum,walletBalance),customerToken)
    ########################################
    ### 如果wallet的钱够, 从wallet里面转钱到miner
    if(minerAvailable > availableDifference*2):
      withdrawRewards(availableDifference)
      sendDingdingMessage("机器:%s 通知: 矿工wallet余额不足,触发自动从miner转账完成"%(hostname))

  ### miner available 余额小于 InitialPledgeRequirement 就报警
  if(minerIPR != -1 and minerAvailable != -1 and minerAvailable < availableDifference):
    available_diff_health = False
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner Available less than %s, send warning"%availableDifference)
    #sendDingdingMessage("机器:%s 严重警告: 矿工账户抵押物不足！矿工账户available为 %s, 抵押金额 %s"%(hostname,minerAvailable,minerIPR))
    ### 如果wallet的钱够, 从wallet里面转钱到miner
    if(walletBalance > availableDifference):
      sendMoneyToMiner(minerNum,availableDifference)
      sendDingdingMessage("机器:%s 通知: 矿工账户抵押物不足,触发自动转帐给矿工账户完成"%(hostname))

  ### 第5步：检查master的消息池健康状态  #########################################################
  curMsg=-1; futureMsg=-1
  
  nonce_health = True
  pastMsg,curMsg,futureMsg = checkMpoolStat()
  msgStatus = "本地消息池数量: past: %s, cur: %s, future: %s"%(pastMsg,curMsg,futureMsg)
  if(int(curMsg) != -1 and int(curMsg) > msgThreshold):
    nonce_health = False
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"mpool current msg number more than %s, send warning"%msgThreshold)
    #sendDingdingMessage("机器:%s 严重警告: 矿工消息池待上链消息太多, 当前排队消息数量 %s"%(hostname,curMsg))
  if(int(futureMsg) > 0 or int(pastMsg) > 0):
    nonce_health = False
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"mpool has future msg, need fix, send warning")
    #sendDingdingMessage("机器:%s 严重警告: 矿工消息池Nonce需要fix, future消息数量 %s"%(hostname,futureMsg))


  ### 第6步：汇总检查报告  #########################################################
  report = "\n机器 %s 节点号 %s 的体检报告: "%(hostname,minerNum)
  if(process_health and chain_health and wallet_health and available_diff_health and nonce_health):
    report += "目前lotus进程, 区块高度, 钱包余额, 矿工抵押物, 消息池, 一切健康!!!"
  elif(not process_health):
    report += "\n严重警告: lotus 进程挂了!!! daemon 进程数量: %s. miner 进程数量: %s "%(daemonN,minerN)
  elif(not chain_health):
    report += "\n严重警告: 区块落后超过 %s 分钟"%(int(secDelta/60.0))
  elif(not wallet_health):
    report += "\n严重警告: wallet钱包余额不足,请尽快接水龙头!!! 当前余额为 %s"%(walletBalance)
  elif(not available_diff_health):
    report += "\n严重警告: 矿工账户抵押物不足!!!矿工账户available为 %s, 抵押金额为 %s"%(minerAvailable,minerIPR)
  elif(not nonce_health):
    report += "\n严重警告: 矿工消息池Nonce需要fix!!! 本地消息池消息数量 past: %s, cur: %s, future: %s"%(pastMsg,curMsg,futureMsg)
  sendDingdingMessage(report + "\n" + powerStatus + "\n" + sectorsStat + "\n" +msgStatus + "\n" + walletStatus,customerToken)
  if(hostname in customerInfoDict.keys()):
    customerToken=customerInfoDict[hostname][0]    ##### 填写客户的钉钉群的url
    #sendDingdingMessage(report + "\n" + powerStatus + "\n" + sectorsStat + "\n" +msgStatus + "\n" + walletStatus,customerToken)