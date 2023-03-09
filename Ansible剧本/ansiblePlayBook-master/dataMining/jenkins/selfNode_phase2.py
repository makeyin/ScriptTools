##### python3 selfNode.py --hour=1
##### 用来统计某个节点自己挖的block，多少个上链了，没有上链的block数量
##### 分析未上链的block的原因，方法是拿到这个block的parent，分析这个parent block的时间戳，和获取这个block的时间戳
##### 查看挖矿相关的日志：tail -f `ls -lt ~/log | awk '{print $NF}' | grep storage-miner | head -1` | egrep "mined new block|mineoneSep|received all tasks waitting|loop|received partial tasks"
import os,sys
import json
import time
from datetime import datetime, timedelta
import numpy as np
import math

def to24TimeFormat(unixTime):
  time_local = time.localtime(int(unixTime))
  #转换成新的时间格式(2016-05-05 20:28:54)
  dt = time.strftime("%Y-%m-%dT%H:%M:%S",time_local)
  return dt

def calZeroRate(rate,totalPower):
  #totalPower=3*1024*1024 #G
  tmp=totalPower/sectorSize
  p=5*25/tmp
  num= math.ceil((tmp*rate)/25.0)
  res = format((1-p)**num,'.4f')
  return float(res)

def calExpectRate(rate):
  res = 0.0
  if (rate > 0.2):
    res = 1.0
  else:
    res = rate*5.0
  return float(res)

def getOnChainInfo(minerId,startTime,endTime):
  #获取该节点上链的block个数
  startTime_f = time.strftime("%b %d %H:%M:%S", time.strptime(startTime, "%Y-%m-%dT%H:%M:%S"))
  endTime_f = time.strftime("%b %d %H:%M:%S", time.strptime(endTime, "%Y-%m-%dT%H:%M:%S"))
  #如果日02格式,将前面的0去掉
  if(startTime_f.split(" ")[1].startswith('0')):
    startTime_f = startTime_f.replace("0", " ", 1)
    endTime_f = endTime_f.replace("0", " ", 1)
  chainListFileTmp="chainList.txt_withTime"
  chainCmd=""" ~/bin/lotus chain list --count=2000 | awk -F'[()]' '{if($2>"%s" && $2<"%s")print $0}' > %s """%(startTime_f,endTime_f,chainListFileTmp)
  os.popen(chainCmd)
  time.sleep(5)

  ###全网预期出块数
  struct_endTime, struct_startTime = time.mktime(time.strptime(endTime, "%Y-%m-%dT%H:%M:%S")), time.mktime(time.strptime(startTime, "%Y-%m-%dT%H:%M:%S"))
  expectedNetBlockNum=(float(struct_endTime)-float(struct_startTime))/block_time
  ###实际出块数量
  totalBlockNum=os.popen("cat %s| wc -l"%chainListFileTmp).read().rstrip()

  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"############################################################")
  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"统计时间 %s 至  %s , 期间全网预出个数 %s, 实际出块个数 %s"%(startTime,endTime,int(expectedNetBlockNum),totalBlockNum))
  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"############################################################")

  chainMinerCmd=""" grep %s %s> %s """%(minerId,chainListFileTmp,onChainBlockFile)
  #print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"%s 节点出块中上链的信息保存为 %s"%(minerId,onChainBlockFile))
  os.popen(chainMinerCmd)
  return expectedNetBlockNum

def getLogWithTime():
  #按照需要的间段切割lotus日志
  #logFileWithinTimeCmd="""grep '^2020' --text %s| awk '{if($1 > "%s" && $1 < "%s"){print $0}}' > %s"""%(logFile,startTime,endTime,logFileWithTime)
  #os.popen(logFileWithinTimeCmd)
  #time.sleep(15)
  #按照时间段切割lotus storage miner日志
  mlogFileWithinTimeCmd="""grep '^2020' --text %s | egrep -a "get mbi info timeout|mining delay|mined new block|mineOneSep|loop|received w-tasks waitting|IsTicketWinner|get beacon entries failed|received tasks timeout|alltasks len: 66|attempting to mine a block" | awk '{if($1 > "%s" && $1 < "%s"){print $0}}' > %s"""%(mlogFile,startTime,endTime,mineLogFile)
  print(mlogFileWithinTimeCmd)
  os.popen(mlogFileWithinTimeCmd)
  time.sleep(15)
  #按照需要的时间段将挖矿相关日志保存
  #mineLogCmd="""egrep "mined new block|mineoneSep|received all tasks waitting|loop" --text %s| awk '{if($1 > "%s" && $1 < "%s"){print $0}}' > %s """ % (mlogFile,startTime,endTime,mlogFileWithTime)
  #os.popen(mineLogCmd)
  #time.sleep(15)

  # cidCmd=""" egrep "Created Block With Proof" %s > %s""" % (mineLogFile,selfCreatedBlockFile)
  # os.popen(cidCmd)
  # time.sleep(5)

def formatTimeInLog(old):
  # 单位转化为ms
  if("ms" in old):
    new = float(old.split("ms")[0])
  elif("m" in old and "ms" not in old):
    minutes = old.split("m")[0]
    seconds = old.split("m")[1].split("s")[0]
    new = float(minutes)*60*1000 + float(seconds)*1000
  elif("µs" in old):
    new = float(old.split("µs")[0])/1000.0
  elif("ns" in old):
    new = float(old.split("ns")[0])/1000000.0
  else:
    t = old.split("s")[0]
    new = (float(t)*1000.0)
  return new

  ### mined new block       {"cid": "bafy2bzacebfyaiuvtaeoafanpgx4i5ohyv3t5r5qf4v4nvynqy54u3gwtgyqi", "height": "1057",
  # "totalTook": "6.489318047s", "mineOneSepTook": "289.127586ms", "waitVaniTook": "1.000360408s", "computeSnarkProofsTook": "5.176802038s"}
def calMineTimeCostNewLog(mineLogFile):
  cmd=""" egrep "mined new block" %s | awk -F'new block' '{print $2}' """ % (mineLogFile)
  #print(cmd)
  jsonStrList = os.popen(cmd).read().rstrip().split("\n")
  if (jsonStrList[0]==""):
    return
  for j in jsonStrList:
    blockJson = json.loads(j.rstrip().lstrip())
    #print(blockJson)
    selfMinedBlockList.append(blockJson["cid"])
    Total_TimeList.append(formatTimeInLog(blockJson["totalTook"]))
    mineOneSep_TimeList.append(formatTimeInLog(blockJson["mineOneSepTook"]))
    waitVani_TimeList.append(formatTimeInLog(blockJson["waitVaniTook"]))
    computeSnarkProofs_TimeList.append(formatTimeInLog(blockJson["computeSnarkProofsTook"]))

def calMineoneSepTimeCost(mineLogFile):
  cmd=""" egrep "mineOneSep" %s | grep ticketTook |  awk -F'mineOneSep' '{print $2}' """ % (mineLogFile)
  print(cmd)
  jsonStrList = os.popen(cmd).read().rstrip().split("\n")
  if (jsonStrList[0]==""):
    return
  for j in jsonStrList:
    if(j==""):
      continue
    blockJson = json.loads(j.rstrip().lstrip())
    mineOneSepTotal_TimeList.append(formatTimeInLog(blockJson["totalTook"]))
    mbiTook_TimeList.append(formatTimeInLog(blockJson["mbiTook"]))
    beaconTook_TimeList.append(formatTimeInLog(blockJson["beaconTook"]))
    ticketTook_TimeList.append(formatTimeInLog(blockJson["ticketTook"]))
    isWinTook_TimeList.append(formatTimeInLog(blockJson["isWinTook"]))
    randTook_TimeList.append(formatTimeInLog(blockJson["randTook"]))
    sindexTook_TimeList.append(formatTimeInLog(blockJson["sindexTook"]))
    assembleTook_TimeList.append(formatTimeInLog(blockJson["assembleTook"]))
    #disTook_TimeList.append(formatTimeInLog(blockJson["disTook"]))

def printNumpyRes(alist,name):
  avg = format(np.average(alist),'.2f')
  std = format(np.std(alist),'.2f')
  minV = format(np.min(alist),'.2f')
  maxV = format(np.max(alist),'.2f')
  v10 = format(np.percentile(alist,10),'.2f')
  v50 = format(np.percentile(alist,50),'.2f')
  v90 = format(np.percentile(alist,90),'.2f')
  v95 = format(np.percentile(alist,95),'.2f')
  v97 = format(np.percentile(alist,97),'.2f')
  v98 = format(np.percentile(alist,98),'.2f')
  v99 = format(np.percentile(alist,99),'.2f')
  #print ("phase          avg         std         min         10%分位         50%分         90%分位         95%分位         97%分位         98%分位         99%分位         max")
  #print(name,avg,std,minV,v10,v50,v90,maxV)
  print("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s  %10s  %10s  %10s  %10s"%(name,avg,std,minV,v10,v50,v90,v95,v97,v98,v99,maxV))


def analyzeSelfMinedBlock():
  #获取上链的block cid集合
  selfOnChainBlockStr = os.popen("cat %s"%onChainBlockFile).read().rstrip()
  selfOnChainBlockNum = os.popen("cat %s | wc -l"%onChainBlockFile).read().rstrip()

  #打印本节点挖到了但是没有上链的block cid
  #selfMinedBlockList = os.popen("cat %s| awk '{print $NF}'"%selfCreatedBlockFile).read().rstrip().split("\n")
  selfMinedNum=len(selfMinedBlockList)
  lostBlockList=[]
  for blockCid in selfMinedBlockList:
    if( blockCid not in selfOnChainBlockStr):
      lostBlockList.append(blockCid)
      #print(blockCid)

  loopCount=os.popen("grep 'loop' %s | wc -l"%mineLogFile).read().rstrip()
  getBeaconFailCount=os.popen("grep 'get beacon entries failed' %s | wc -l"%mineLogFile).read().rstrip()
  winnerTrueCount=os.popen(""" grep "IsTicketWinner" %s | grep  "true" | wc -l """%mineLogFile).read().rstrip()
  winnerFalseCount=os.popen(""" grep "IsTicketWinner" %s | grep "false" | wc -l """%mineLogFile).read().rstrip()
  receiveSlaveSuccessCount=os.popen(""" grep "alltasks len: 66" %s | wc -l """%mineLogFile).read().rstrip()
  mbiTimeoutCount=os.popen(""" grep "mbi info timeout" %s | wc -l """%mineLogFile).read().rstrip()
  sendToPosterFailedCount=os.popen(""" grep "received tasks timeout" %s | grep "sents: 0"| wc -l """%mineLogFile).read().rstrip()
  receiveSlaveFailedCount=os.popen(""" grep "received tasks timeout" %s | grep "received: 0"| grep "sents: 1" | wc -l """%mineLogFile).read().rstrip()
  miningDelayCount=os.popen(""" grep "mining delay" %s | wc -l """%mineLogFile).read().rstrip()
  minedBlockCount=os.popen(""" grep "mined new block" %s |wc -l """%mineLogFile).read().rstrip()
  print("该时间段理论的挖矿轮数: ",int(expectedNetBlockNum))
  print("  本节点触发挖矿的次数: ",loopCount,"        未拿到beacon的次数: ",getBeaconFailCount)
  print("    master刮中奖的次数: ",winnerTrueCount,"        未刮中奖的次数: ",winnerFalseCount)
  print("   收到slave返回的次数: ",receiveSlaveSuccessCount," mbi超时: ",mbiTimeoutCount," 连不上slave: ",sendToPosterFailedCount," 未收到slave返回: ",receiveSlaveFailedCount," 超时被截断: ",miningDelayCount)
  print("          挖到矿的次数: ",minedBlockCount)
  print("            上链的个数: ",selfOnChainBlockNum)

  print("====超时被截断的日志")
  miningDelayLogs=os.popen(""" grep "mining delay" %s"""%mineLogFile).read().rstrip()
  print(miningDelayLogs)

  ###计算期望的出块率
  #全网总算，大小为G
  totalPowerCmd="~/bin/lotus state power"
  totalNetPower=int(os.popen(totalPowerCmd).read().rstrip().split("(")[0])/(1024*1024*1024)
  nodePower=os.popen("~/bin/lotus state power %s"%selfMinerId).read().rstrip()
  power=nodePower.split("~= ")[-1].replace("%","")
  #expectRate = 1.0 - calZeroRate(float(power)/100,totalNetPower)
  expectRate = calExpectRate(float(power)/100)
  expectRate = format(expectRate*100,'.2f')
  actualSelfRate = format(float(selfMinedNum)*100/float(expectedNetBlockNum), '.2f')
  actualOnlineRate = format(float(selfOnChainBlockNum)*100/float(expectedNetBlockNum), '.2f')

  #print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"节点 %s 此间本地总共挖到的block个数为 %s"%(selfMinerId,selfMinedNum))
  print("---------------------------------------------------------------------------------------------------------------")
  print("%-10s %10s %10s %10s %10s %10s %10s"%("预期出块率","本地挖到数量","本地出块率","上链数量","上链出块率","未上链数量","未上链率"))
  if(selfMinedNum!=0):
    lostRate = format(len(lostBlockList)*100/selfMinedNum,'.2f')
  else:
    lostRate = 0.0
  print("%6s%%     %12s    %14s%%    %12s     %12s%%     %12s    %12s%%"%(expectRate,selfMinedNum,actualSelfRate,selfOnChainBlockNum,actualOnlineRate,len(lostBlockList),lostRate))
  print("---------------------------------------------------------------------------------------------------------------")

  print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"未上链的block cid分别为：")
  if(lostBlockList == []):
    print("无")
  else:
    #print(lostBlockList)
    print("%-30s                                 %10s    %10s     %10s"%("block_cid","height","createdtime_fromLog","block_timestamp"))
    for cid in lostBlockList:
      height = os.popen("~/bin/lotus chain getblock %s| grep Height | awk '{print $NF}'| awk -F',' '{print $1}'"%cid).read().rstrip()
      timeU = os.popen("~/bin/lotus chain getblock %s| grep Timestamp | awk '{print $NF}'| awk -F',' '{print $1}'"%cid).read().rstrip()
      if(timeU==''):
        timeU = -1
      else:
        timeU = to24TimeFormat(timeU)
      timeLog = os.popen("grep %s %s|awk '{print $1}'"%(cid,mineLogFile)).read().rstrip()
      print("%-30s %10s   %20s    %20s"%(cid,height,timeLog.split(".")[0],timeU))

def delete_files(logfilename,mlogfilename):
  for root, dirs, filesin in os.walk(path):
    for filename in filesin:
      if filename == logfilename or filename == mlogfilename:
        os.remove(os.path.join(filename))
        print("Delete file:",(filename))

if __name__ == '__main__':
  ##### Usage:  startTime和endTime是写清楚分析的时间段
  ##### 如果分析节���为本节点，则需要研究logm日志，False意思就是分析其他节点，则���需要研究lotus log
  logFile = os.popen("ls -l /home/devnet/log | grep  lotus | grep -v _withTime |tail -n 1 | awk '{print $9}'").read().rstrip()
  #mlogFile = "storage-miner.05181838.out"
  mlogFile = os.popen("ls -l /home/devnet/log | grep  storage | grep -v _withTime |tail -n 1 | awk '{print $9}'").read().rstrip()
  block_time = 25  #s
  #sectorSize=float(32.0)  #G
  sectorSize=float(0.5)  #G
  #######################################
  import argparse

  parser = argparse.ArgumentParser(description='manual to this script')
  parser.add_argument('--startTime', default="2020-06-08T17:00:00", type=str)
  parser.add_argument('--endTime', default="2020-06-08T17:20:00", type=str)
  parser.add_argument('--hour', default=0, type=int)
  parser.add_argument('--min', default=0, type=int)
  args = parser.parse_args()
  startTime = args.startTime
  endTime = args.endTime
  hour_interval = args.hour
  min_interval = args.min
  if(hour_interval!=0 or min_interval!=0):
    ###采用相对时间，获取hour_interval和min_interval 前的时间
    min_interval = min_interval + 1
    startTime = (datetime.now() - timedelta(hours=hour_interval,minutes=min_interval)).strftime("%Y-%m-%dT%H:%M:%S")
    endTime = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
  ###求出本节点的miner id
  selfMinerId = os.popen("~/bin/lotus-storage-miner info | grep 'Miner:' | awk '{print $NF}'").read().rstrip()
  ###按照需求分离和切割日志
  #logFileWithTime=logFile + "_withTime"
  mlogFileWithTime=mlogFile + "_withTime"
  mineLogFile="mineLog_"+selfMinerId+".txt"
  #selfCreatedBlockFile="selfCreatedCid_"+selfMinerId +".txt"
  getLogWithTime()

  ###  统计mineoneSep时间分布
  ### {"totalTook": "289.042248ms", "mbiTook": "267.650854ms", "beaconTook": "1.509µs",
  # "ticketTook": "8.394182ms", "isWinTook": "6.776472ms", "randTook": "472.48µs", "sindexTook": "753.416µs", "assembleTook": "3.67696ms", "disTook": "34.357µs"}
  mineOneSepTotal_TimeList=[]
  mbiTook_TimeList=[]
  beaconTook_TimeList=[]
  ticketTook_TimeList=[]
  isWinTook_TimeList=[]
  randTook_TimeList=[]
  sindexTook_TimeList=[]
  assembleTook_TimeList=[]
  #disTook_TimeList=[]
  calMineoneSepTimeCost(mineLogFile)
  if(mineOneSepTotal_TimeList == []):
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"挖矿相关的日志为空,请检查日志")
    sys.exit(1)
  else:
    print("------------------------------------ 统计 mineoneSep 时间分布 (ms) ------------------------------------------------------------------")
    print ("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s   %10s   %10s  %10s  %10s"%("[module]","[avg]","[std]","[min]","[10th]","[50th]","[90th]","[95th]","[97th]","[98th]","[99th]","[max]"))
    printNumpyRes(mbiTook_TimeList,"mbiTook")
    printNumpyRes(beaconTook_TimeList,"beaconTook")
    printNumpyRes(ticketTook_TimeList,"ticketTook")
    printNumpyRes(isWinTook_TimeList,"isWinTook")
    printNumpyRes(randTook_TimeList,"randTook")
    printNumpyRes(sindexTook_TimeList,"sindexTook")
    printNumpyRes(assembleTook_TimeList,"assembleTook")
    #printNumpyRes(disTook_TimeList,"disTook")
    printNumpyRes(mineOneSepTotal_TimeList,"mineOneSepTotal")
    print("-----------------------------------------------------------------------------------------------------------------------------------")
    print("\n")

  ###  统计挖矿的时间分布
  ### mined new block       {"cid": "bafy2bzacebfyaiuvtaeoafanpgx4i5ohyv3t5r5qf4v4nvynqy54u3gwtgyqi", "height": "1057",
  # "totalTook": "6.489318047s", "mineOneSepTook": "289.127586ms", "waitVaniTook": "1.000360408s", "computeSnarkProofsTook": "5.176802038s"}
  selfMinedBlockList=[]
  mineOneSep_TimeList=[]
  waitVani_TimeList=[]
  computeSnarkProofs_TimeList=[]
  Total_TimeList=[]
  calMineTimeCostNewLog(mineLogFile)
  if(selfMinedBlockList == []):
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"该时段内没有挖到矿!!!")
  else:
    print("------------------------------------- 统计 new block 时间分布 (ms) ------------------------------------------------------------------")
    print ("%-16s   %10s   %10s  %10s   %10s   %10s  %10s  %10s   %10s   %10s  %10s  %10s"%("[module]","[avg]","[std]","[min]","[10th]","[50th]","[90th]","[95th]","[97th]","[98th]","[99th]","[max]"))
    printNumpyRes(mineOneSep_TimeList,"mineOneSeperate")
    printNumpyRes(waitVani_TimeList,"waitVani")
    printNumpyRes(computeSnarkProofs_TimeList,"computeSnarkProofs")
    printNumpyRes(Total_TimeList,"total")
    print("-----------------------------------------------------------------------------------------------------------------------------------")
    print("\n")

  ###获取指定时间段内的链上的区块信息
  onChainBlockFile="onChainCid_"+selfMinerId+".txt"
  expectedNetBlockNum=getOnChainInfo(selfMinerId,startTime,endTime)
  path="/home/devnet/log"
  ###分析节点本地的挖到的block信息
  analyzeSelfMinedBlock()
  #delete_files(logFileWithTime,mlogFileWithTime)