import os
import time

#重要的常量定义
POWER_FIELD_NUM = 2
FIELD_NUM = 9
MAX_TOSEAL = 800*1024
TOSEAL_LIMIT1 = 40*1024 #most thirsty
TOSEAL_LIMIT2 = 80*1024
TOSEAL_LIMIT3 = 120*1024


#中间状态变量
recipientMostDict = {} #ip:toSeal
recipientMoreDict = {} #ip:toSeal
recipientMuchDict = {} #ip:toSeal
blockLaggingMinersDick = {}  #ip:nodeBlockHeight
blockLaggingMinersList = []  #[(ip:nodeBlockHeight)]

#重要的变量
senderList = [] #read from offline calculate [(ip:power)]
minersDict = {} #ip:MinerInfo Object
blockLaggingIPList = []  #[ip]

recipientMostList = [] #[ip]
recipientMoreList = []
recipientMuchList = []
senderAvailableList = [] #[ip]


#$miningAddress,$stagingSize,$sealedSize,$lastSealedSize,$nodeBlockHeight,$IPFSBlockHeight     
class MinerInfo(object):
    def __init__(self,strList):
        self.ip = strList[0]
        self.minerAddress = strList[1]
        self.power = int(strList[2]) if strList[2] != "" else 0
        self.staging = int(strList[3]) if strList[3] != "" else 0
        self.sealed = int(strList[4]) if strList[4] != "" else 0
        self.lastSealed = int(strList[5]) if strList[5] != "" else 0
        self.nodeBlockHeight = int(strList[6]) if strList[6] != "" else 0
        self.ipfsBlockHeight = int(strList[7]) if strList[7] != "" else 0
        #self.ip,self.minerAddress,self.power,self.staging,self.sealed,self.lastSealed,self.nodeBlockHeight,self.ipfsBlockHeight = strList
        self.toSeal = self.getToSeal()
        self.recipientAddress = []
        self.recipientIP = []
    
    def getToSeal(self):
        return int(self.staging) + int(self.lastSealed) - int(self.sealed)

def getSenderList(fileName):
    global senderList
    senderDict = {}
    with open(fileName, 'r') as f:
        content = f.readlines()
        for i in content:
            strList = i.rstrip().split(",")
            if len(strList) == POWER_FIELD_NUM:
                senderDict[strList[0]] = int(strList[1])
    senderList = sorted(senderDict.items(), key=lambda d:d[1], reverse = False)

    #限制发送算力的client个数
    if(len(senderList) > Max_Sender_Num):
        senderList = senderList[:Max_Sender_Num]

# user filecoin repo miner info
def getMinerInfo(file_name):
    #print(file_name)
    global recipientMostList,recipientMoreList,recipientMuchList,blockLaggingMinersList,blockLaggingIPList,senderAvailableList

    with open(file_name, 'r') as f:
        content = f.readlines()
        for i in content:
            strList = i.rstrip().split(",")
            if len(strList) == FIELD_NUM:
                groupRecepient(strList)

    #区块落后的IP保存在blockLaggingIPList
    blockLaggingMinersList = sorted(blockLaggingMinersDick.items(), key=lambda d:d[1], reverse = True)
    #print("blockLaggingMinersList: ",blockLaggingMinersList)
    lagginIDX = [i for i,x in enumerate(blockLaggingMinersList) if x[1] < blockLaggingMinersList[0][1]-blockLaggingThreshhold]
    blockLaggingIPList = [blockLaggingMinersList[i][0] for i in lagginIDX]
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: the block height is lagging, abandon the IP List: ",blockLaggingIPList)

    #过滤掉区块落后的
    recipientMostList = sorted(recipientMostDict.items(), key=lambda d:d[1], reverse = False) 
    recipientMostList = [i[0] for i in recipientMostList if i[0] not in blockLaggingIPList]

    recipientMoreList = sorted(recipientMoreDict.items(), key=lambda d:d[1], reverse = False) 
    recipientMoreList = [i[0] for i in recipientMoreList if i[0] not in blockLaggingIPList]

    recipientMuchList = sorted(recipientMuchDict.items(), key=lambda d:d[1], reverse = False)
    recipientMuchList = [i[0] for i in recipientMuchList if i[0] not in blockLaggingIPList]


    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," get senderList: ",senderList)
    senderAvailableList = [i[0] for i in senderList if i[0] not in blockLaggingIPList]
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," after remove the block lagging, available sender list: ",senderAvailableList)
    #print("Most thirsty recipients list: ",recipientMostList)
    #print("More thirsty recipients list: ",recipientMoreList)
    #print("Much thirsty recipients list: ",recipientMuchList)

    #清理不需要的数据
    # recipientMostDict = {} #ip:toSeal
    # recipientMoreDict = {} #ip:toSeal
    # recipientMuchDict = {} #ip:toSeal
    # blockLaggingMinersDick = {}

def groupRecepient(strList):
    global recipientMostDict,recipientMoreDict,recipientMuchDict,blockLaggingMinersDick
    
    miner = MinerInfo(strList)
    #miner地址没有，过滤掉
    if(miner.minerAddress == "" or miner.minerAddress == "empty"):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: abandon the miner since it has no miner address: ",miner.ip)
        return 0
    #待seal数据超过800G,就休息一下
    if(miner.toSeal > MAX_TOSEAL):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: to seal size > 180GB, do not consider as a recipient or sender: ",miner.ip)
        return 0
    minersDict[miner.ip] = miner
    blockLaggingMinersDick[miner.ip] = miner.nodeBlockHeight

    if(miner.toSeal <= TOSEAL_LIMIT1):
        recipientMostDict[miner.ip] = miner.toSeal
    elif(miner.toSeal > TOSEAL_LIMIT1 and miner.toSeal < TOSEAL_LIMIT2):
        recipientMoreDict[miner.ip] = miner.toSeal
    elif(miner.toSeal > TOSEAL_LIMIT2 and miner.toSeal < TOSEAL_LIMIT3):
        recipientMuchDict[miner.ip] = miner.toSeal
    else:
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: to seal size > TOSEAL_LIMIT3 ",TOSEAL_LIMIT3, "M, do not consider as a recipient: ",miner.ip)

def matchSenderRecipient():
    #正常情况下，sender数量是大于recipients数量
    senderLen = len(senderAvailableList)
    mostLen, moreLen, muchLen = len(recipientMostList), len(recipientMoreList), len(recipientMuchList)
    recipientLen = mostLen + moreLen + muchLen

    if(senderLen == 0 ):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," ERROR: no sender!!!")
        return {}

    if(recipientLen == 0):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," ERROR: no recipient!!!")
        return {}

    senderRecipientListMapping = {} # [senderIP:[recipient1 minerAddress, recipient2 minerAddress]]
    if(senderLen < recipientLen):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," WARNING: sender number is less than recipient number, need add more sender")

    emptyRecipientList = []
    emptySenderList = []

    if(senderLen < mostSenderTimes):
        #sender 小于4，就每个sender给每个recipient发
        recipList = recipientMostList + recipientMoreList + recipientMuchList
        if( senderLen==1 and recipientLen==1 and recipList[0] == senderAvailableList[0]):
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," ERROR: available sender and recipient is the same one!!!")
            return {}
        for i,s in enumerate(senderAvailableList):
            for recip in recipList:
                if s != recip:
                    if s not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[s] = [ minersDict[recip].minerAddress ]
                    else:
                        senderRecipientListMapping[s].append(minersDict[recip].minerAddress)
    if(senderLen < recipientLen and senderLen >= mostSenderTimes):
        #sender个数小于recipient, 每个sender发送给4个recipients
        recipList = recipientMostList + recipientMoreList + recipientMuchList
        for i,s in enumerate(senderAvailableList):
            for ni in range(0,mostSenderTimes): 
                if i + ni <= (recipientLen-1) and s != recipList[i + ni]:
                    if s not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[s] = [ minersDict[recipList[i + ni]].minerAddress ]
                    else:
                        senderRecipientListMapping[s].append(minersDict[recipList[i + ni]].minerAddress)

    if(senderLen >= recipientLen and senderLen >= mostSenderTimes):
        for i,s in enumerate(recipientMostList):
            for ni in range(0,mostSenderTimes): 
                if i + ni <= (senderLen-1) and s != senderAvailableList[i + ni]:
                    if senderAvailableList[i + ni] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[i + ni]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[i + ni]].append(minersDict[s].minerAddress)
                elif i + ni <= (senderLen-1) and s == senderAvailableList[i + ni]:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," DEBUG: sender cannot send to itself, deal with the recipient later: ",s)
                    emptySenderList.append(s)
                    emptyRecipientList.append(s)
                elif i + ni > (senderLen-1) and s != senderAvailableList[i + ni - senderLen]:
                    if senderAvailableList[i + ni - senderLen] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[i + ni - senderLen]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[i + ni - senderLen]].append(minersDict[s].minerAddress)
        
        for i,s in enumerate(recipientMoreList):
            for ni in range(0,moreSenderTimes): 
                if mostLen + i + ni <= (senderLen-1) and s != senderAvailableList[mostLen + i + ni]:
                    if senderAvailableList[mostLen + i + ni] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[mostLen + i + ni]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[mostLen + i + ni]].append(minersDict[s].minerAddress)
                elif mostLen + i + ni <= (senderLen-1) and s == senderAvailableList[mostLen + i + ni]:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," DEBUG: sender cannot send to itself, deal with the recipient later: ",s)
                    emptySenderList.append(s)
                    emptyRecipientList.append(s)
                elif mostLen + i + ni > (senderLen-1) and s != senderAvailableList[mostLen + i + ni - senderLen]:
                    if senderAvailableList[mostLen + i + ni - senderLen] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[mostLen + i + ni - senderLen]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[mostLen + i + ni - senderLen]].append(minersDict[s].minerAddress)
        
        for i,s in enumerate(recipientMuchList):
            for ni in range(0,muchSenderTimes): 
                if moreLen + mostLen + i + ni <= (senderLen-1) and s != senderAvailableList[moreLen + mostLen + i + ni]:
                    if senderAvailableList[moreLen + mostLen + i + ni] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[moreLen + mostLen + i + ni]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[moreLen + mostLen + i + ni]].append(minersDict[s].minerAddress)
                elif moreLen + mostLen + i + ni <= (senderLen-1) and s == senderAvailableList[moreLen + mostLen + i + ni]:
                    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," DEBUG: sender cannot send to itself, deal with the recipient later: ",s)
                    emptySenderList.append(s)
                    emptyRecipientList.append(s)
                elif moreLen + mostLen + i + ni > (senderLen-1) and s != senderAvailableList[moreLen + mostLen + i + ni - senderLen]:
                    if senderAvailableList[moreLen + mostLen + i + ni - senderLen] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[moreLen + mostLen + i + ni - senderLen]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[moreLen + mostLen + i + ni - senderLen]].append(minersDict[s].minerAddress)
        
        if(emptyRecipientList != [] and len(emptyRecipientList) <= senderLen):
            for i,s in enumerate(emptyRecipientList):
                if s != senderAvailableList[i]:
                    if senderAvailableList[i] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[i]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[i]].append(minersDict[s].minerAddress)
                elif i-1 >= 0 and s != senderAvailableList[i-1]:
                    if senderAvailableList[i-1] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[i-1]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[i-1]].append(minersDict[s].minerAddress)
                    continue
                elif i+1 < senderLen and s != senderAvailableList[i+1]:
                    if senderAvailableList[i+1] not in senderRecipientListMapping.keys():
                        senderRecipientListMapping[senderAvailableList[i+1]] = [ minersDict[s].minerAddress ]
                    else:
                        senderRecipientListMapping[senderAvailableList[i+1]].append(minersDict[s].minerAddress)
                    continue
    return senderRecipientListMapping

def writeSenderRecipientMappingFile(inputFile,outputFile,mapping):
    hostInfoDict = {}
    with open(inputFile, 'r') as f:
        content = f.readlines()
        for line in content:
            if line.startswith("["):
                continue
            strList = line.rstrip().split(" ")[0]
            if strList in mapping.keys():
                hostInfoDict[strList] = line.rstrip()
    
    with open(outputFile,'w') as f:
        f.write("[client]\n")
        for host in hostInfoDict.keys():
            li = ",".join(mapping[host])
            f.write('%s recipientList="%s"\n'%(hostInfoDict[host],li))
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," write to client_host: ",li)

if __name__ == '__main__':
    ##############
    path = os.path.expanduser('~')
    powerFileName = path + "/clientData/powerRank.txt"
    minerMonitorFileName = path + "/clientData/minerMonitor.txt"
    # 放在与playbook同一级目录
    fatherPath= os.path.dirname(os.path.realpath(__file__))+"/../../.."
    playBookHostFile = fatherPath + "/hosts"
    clientHostOutputFile = path + "/clientData/client_host"
    ##############

    # parse params
    import argparse
    parser = argparse.ArgumentParser(description='manual to this script')
    parser.add_argument('--mostSenderTimes', type=int, default = 4)
    parser.add_argument('--moreSenderTimes', type=int, default = 2)
    parser.add_argument('--muchSenderTimes', type=int, default = 1)
    parser.add_argument('--blockLaggingThreshhold', type=int, default = 1)
    parser.add_argument('--Max_Sender_Num', type=int, default = 10)
    parser.add_argument('--TOSEAL_LIMIT3', type=int, default = 122880)
    args = parser.parse_args()
    mostSenderTimes = args.mostSenderTimes
    moreSenderTimes = args.moreSenderTimes
    muchSenderTimes = args.muchSenderTimes
    blockLaggingThreshhold = args.blockLaggingThreshhold
    
    Max_Sender_Num = args.Max_Sender_Num
    TOSEAL_LIMIT3 = args.TOSEAL_LIMIT3

    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," Params: Max_Sender_Num ",Max_Sender_Num,", blockLaggingThreshhold ",blockLaggingThreshhold," , mostSenderTimes ",mostSenderTimes )
    #print("-------- clientHostOutputFile ",clientHostOutputFile)
    #print("-------- ",playBookHostFile)
    getSenderList(powerFileName)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: sender List: ",senderList)

    if(os.path.exists(minerMonitorFileName)):
        getMinerInfo(minerMonitorFileName)
        #print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: get miner info: ",senderList)
    
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: begin to match sender and recipient")
    mapping = matchSenderRecipient()

    if(mapping == {}):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," ERROR: get sender and recipient relationship is empty ")
        exit(1)

    writeSenderRecipientMappingFile(playBookHostFile,clientHostOutputFile,mapping)

    outputFile = path + "/clientData/senderRecipientMapping.txt"
    with open(outputFile,'w') as f:
        for i in mapping.keys():
            f.write("%s:%s\n"%(i,mapping[i]))

    for i in mapping.keys():
        print("Sender: ",i," , Recipient: ", mapping[i])
