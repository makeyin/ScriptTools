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
recipientDict = {} #ip:toSeal
blockLaggingMinersDick = {}  #ip:nodeBlockHeight
blockLaggingMinersList = []  #[(ip:nodeBlockHeight)]

#重要的变量
senderList = [] #read from offline calculate [(ip:power)]
minersDict = {} #ip:MinerInfo Object
blockLaggingIPList = []  #[ip]

recipientList = [] #[ip]
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
    print("--------------",blockLaggingThreshhold)
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
    global recipientList,blockLaggingMinersList,blockLaggingIPList,senderAvailableList

    with open(file_name, 'r') as f:
        content = f.readlines()
        for i in content:
            strList = i.rstrip().split(",")
            if len(strList) == FIELD_NUM:
                getRecepient(strList)

    #区块落后的IP保存在blockLaggingIPList
    blockLaggingMinersList = sorted(blockLaggingMinersDick.items(), key=lambda d:d[1], reverse = True)
    #print("blockLaggingMinersList: ",blockLaggingMinersList)
    lagginIDX = [i for i,x in enumerate(blockLaggingMinersList) if x[1] < blockLaggingMinersList[0][1]-blockLaggingThreshhold]
    blockLaggingIPList = [blockLaggingMinersList[i][0] for i in lagginIDX]
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: the block height is lagging, abandon the IP List: ",blockLaggingIPList)

    #过滤掉区块落后的recipient
    recipientList = sorted(recipientDict.items(), key=lambda d:d[1], reverse = False) 
    recipientList = [i[0] for i in recipientList if i[0] not in blockLaggingIPList]

    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: senderList: ",senderList)
    #过滤掉区块落后的sender，限制sender个数
    senderAvailableList = [i[0] for i in senderList if i[0] not in blockLaggingIPList and i < Max_Sender_Num]
    print(senderAvailableList)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: senderAvailableList: ",senderAvailableList)


def getRecepient(strList):
    global recipientDict,blockLaggingMinersDick
    
    miner = MinerInfo(strList)
    #miner地址没有，过滤掉
    if(miner.minerAddress == ""):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: abandon the miner since it has no miner address: ",miner.ip)
        return 0
    #待seal数据超过800G,就休息一下
    if(miner.toSeal > MAX_TOSEAL):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: to seal size > 180GB, do not consider as a recipient or sender: ",miner.ip)
        return 0
    minersDict[miner.ip] = miner
    blockLaggingMinersDick[miner.ip] = miner.nodeBlockHeight

    if(miner.toSeal <= TOSEAL_LIMIT3):
        recipientDict[miner.ip] = miner.toSeal
    else:
        print(miner.toSeal)
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: to seal size > 120GB, do not consider as a recipient: ",miner.ip)

def matchSenderRecipient():
    #正常情况下，sender数量是大于recipients数量
    senderLen = len(senderAvailableList)
    recipientLen = len(recipientList)

    if(senderLen == 0 ):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," ERROR: no sender!!!")
        return {}

    if(recipientLen == 0):
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," ERROR: no recipient!!!")
        return {}

    senderRecipientListMapping = {} # [senderIP:[recipient1 minerAddress, recipient2 minerAddress]]

    for i,s in enumerate(senderAvailableList):
        for recip in recipientList:
            if s != recip:
                if s not in senderRecipientListMapping.keys():
                    senderRecipientListMapping[s] = [ minersDict[recip].minerAddress ]
                else:
                    senderRecipientListMapping[s].append(minersDict[recip].minerAddress)
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
            print(li)

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
    parser.add_argument('--blockLaggingThreshhold', type=int, default = 1)
    parser.add_argument('--Max_Sender_Num', type=int, default = 10)
    args = parser.parse_args()
    blockLaggingThreshhold = args.blockLaggingThreshhold
    Max_Sender_Num = args.Max_Sender_Num
    
    #print("-------- clientHostOutputFile ",clientHostOutputFile)
    #print("-------- ",playBookHostFile)
    getSenderList(powerFileName)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: sender List: ",senderList)

    if(os.path.exists(minerMonitorFileName)):
        getMinerInfo(minerMonitorFileName)
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," NOTICE: get miner info: ",senderList)
    mapping = matchSenderRecipient()

    writeSenderRecipientMappingFile(playBookHostFile,clientHostOutputFile,mapping)

    outputFile = path + "/clientData/senderRecipientMapping.txt"
    with open(outputFile,'w') as f:
        for i in mapping.keys():
            f.write("%s:%s\n"%(i,mapping[i]))

    for i in mapping.keys():
        print("Sender: ",i," , Recipient: ", mapping[i])
