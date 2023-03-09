# coding=utf-8
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
def sendDingdingMessage(text,token="73adabba2fbb51025f897a8f2a9c4bd48b3e58df0cb7bb06696084a54a348959"):
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

def redeemRewards():
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to send redeem msg...")
    get_rewards_cmd ="~/bin/lotus-miner rewards redeem"
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
        print("丢失的poster的个数: ","未提供应���接的poster peer ID列表")
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
    print("本地区块head的时间戳与当前时间的时间差:",secDelta)
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

    return walletBalance,minerAvailable,minerIPR,minerNum

def checkMpoolStat():
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check mpool stat...")
    mpool = os.popen("~/bin/lotus mpool stat | grep `~/bin/lotus wallet default`").read().rstrip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Lotus mpool stat local: %s"%mpool)

    reg1 = r'future:(.*)'
    im1 = re.compile(reg1)
    res1 = re.findall(im1, mpool)
    futureMsgNum = int(float(res1[0].strip()))

    reg2 = r'cur:(.*),'
    im2 = re.compile(reg2)
    res2 = re.findall(im2, mpool)
    currentMsgNum = int(float(res2[0].strip()))

    return currentMsgNum,futureMsgNum

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
    daemonNum = int(os.popen("""ps -u $USER -f | grep -w "lotus daemon" | grep -v grep |wc -l""").read().rstrip())
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"daemon num: ",daemonNum)

    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to check lotus-miner process...")
    minerNum = int(os.popen("""ps -u $USER -f | grep -w "lotus-miner" | grep -v grep |wc -l""").read().rstrip())
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner num: ",minerNum)
    return daemonNum,minerNum

def sendMoneyToMiner(minerNum,amount):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start to send money from wallet to miner...")
    mpool = os.popen("~/bin/lotus send %s %s"%(minerNum,amount)).read().rstrip()
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Send money done!")

if __name__ == '__main__':
  ################################################################################################
  host_file="slave_host_file"   #记录了slave的host
  phoneNumberList =["15618799939"]
  hostname=os.popen("hostname").read().rstrip()

  parser = argparse.ArgumentParser(description='manual to this script')
  parser.add_argument('--warn', default=False, type=bool)
  args = parser.parse_args()
  sendWarning=args.warn   #是否发送报警短信
  walletBalanceMinimum = 1000 ####设置wallet 余额最小是多少
  availableDifference = 1000  ####设置miner available的余额需要比miner IPR大多少
  customerToken="f7edfdc5b7c7975c4d5188540ac667e90febcf99cf308cb1ac9949f2d446e916"    ##### 填写客户的钉钉群的url
  ################################################################################################

  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"########### Start to check master status")

  ### 第1步：检查lotus 和 miner进程  ##########################################################
  daemonN,minerN = checkProcess()
  if(daemonN!=-1 and daemonN==0):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"daemon 进程数量: %s, send warning"%daemonN)
    sendDingdingMessage("机器:%s 严重警告: lotus daemon 进程数量: %s. lotus daemon 进程挂了!!!"%(hostname,daemonN))
  elif(daemonN!=-1 and daemonN>1):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"daemon 进程数量: %s, send warning"%daemonN)
    sendDingdingMessage("机器:%s 严重警告: lotus daemon 进程数量: %s. lotus daemon 启动了多个进程"%(hostname,daemonN))
  if(minerN!=-1 and minerN==0):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner 进程数量: %s, send warning"%minerN)
    sendDingdingMessage("机器:%s 严重警告: lotus-miner 进程数量: %s. lotus-miner 进程挂了!!!"%(hostname,minerN))
  elif(minerN!=-1 and minerN>1):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner 进程数量: %s, send warning"%minerN)
    sendDingdingMessage("机器:%s 严重警告: lotus-miner 进程数量: %s. lotus-miner 启动了多个进程"%(hostname,minerN))

  ### 第2步：检查master与slave和poster的连接  ################################################
  lostPosterList = []
  #lostPosterList = checkPeersConnection()
  if(len(lostPosterList)>0):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"lost poster peers, send warning")
    sendDingdingMessage("机器:%s 严重警告: lost %s poster peers"%(hostname,len(lostPosterList)))

  ### 第3步：检查master的链是否落后  #########################################################
  secDelta = -1
  secDelta = checkChainList()
  if(secDelta > 300):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"chain is lagging behind, send warning")
    sendDingdingMessage("机器:%s 严重警告: 区块落后超过 %s 分钟"%(hostname,int(secDelta/60.0)))

  ### 第4步：检查master的钱包账户是否充足  #########################################################
  #lowWalletBalance, lowMinerAvailable, lessThanIPR = False # lessThanIPR: miner available less than InitialPledgeRequirement
  minerIPR=-1;minerAvailable=-1;walletBalance=-1
  walletBalance,minerAvailable,minerIPR,minerNum = checkMinerInfo()
  ### wallet余额小于walletBalanceMinimum就报警
  if(walletBalance != -1 and walletBalance < walletBalanceMinimum):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"walletBalance less than %s, send warning"%walletBalanceMinimum)
    sendDingdingMessage("机器:%s 警告: wallet钱包余额不足,请尽快接水龙头！当前余额为 %s"%(hostname,walletBalance))
    #### 缺钱了,发送报警信息到客户的钉钉群 #### 
    ########################################
    sendDingdingMessage("警告: 节点%s的wallet钱包余额不足,请尽快接水龙头！当前余额为 %s"%(minerNum,walletBalance),customerToken)
    ########################################

  ### miner available余额小于 walletBalanceMinimum 就报警
  if(minerAvailable != -1 and minerAvailable < walletBalanceMinimum):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner Available less than %s, send warning"%walletBalanceMinimum)
    sendDingdingMessage("机器:%s 警告: 矿工账户available余额不足！当前余额为 %s"%(hostname,minerAvailable))
  ### miner available 余额小于 InitialPledgeRequirement 就报警
  if(minerIPR != -1 and minerAvailable < minerIPR + availableDifference):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"miner Available less than miner IPR, send warning")
    sendDingdingMessage("机器:%s 严重警告: 矿工账户抵押物不足！矿工账户available为 %s, 抵押金额 %s"%(hostname,minerAvailable,minerIPR))
    ### 如果wallet的钱够, 从wallet里面转钱到miner
    if(walletBalance > availableDifference):
      sendMoneyToMiner(minerNum,availableDifference)
      sendDingdingMessage("机器:%s 通知: 矿工账户抵押物不足！触发自动转账完成"%(hostname))

  ### 第5步：检查master的消息池健康状态  #########################################################
  curMsg=-1; futureMsg=-1
  msgThreshold = 800
  #curMsg,futureMsg = checkMpoolStat()
  if(curMsg != -1 and curMsg > msgThreshold):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"mpool current msg number more than %s, send warning"%msgThreshold)
    sendDingdingMessage("机器:%s 严重警告: 矿工消息池待上链消息太多, 当前排队消息数量 %s"%(hostname,curMsg))
  if(futureMsg > 0):
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"mpool has future msg, need fix, send warning")
    sendDingdingMessage("机器:%s 严重警告: 矿工消息池Nonce需要fix, future消息数量 %s"%(hostname,futureMsg))
