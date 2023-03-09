import os

def getMinerPower(minerUser,fileName,outputFileName):
    minerAddressDict = {}
    powerDict = {}
    powerList = {}
    with open(fileName, 'r') as f:
        content = f.readlines()
        for i in content:
            strList = i.rstrip().split(",")
            if len(strList)==2 and strList[1] != "":
                minerAddressDict[strList[0]]=strList[1]
    for ip in minerAddressDict.keys():
        #powerDict[ip] = 1
        output = os.popen("/home/%s/bin/go-filecoin miner power %s --repodir=/home/%s/.filecoin| awk '{print $1}' "%(minerUser,minerAddressDict[ip],minerUser))
        powerValue = output.read().rstrip()
        print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," get power value is ",powerValue)
        if "Error" not in powerValue and powerValue != "":
            powerDict[ip] = int(powerValue)
        else:
            powerDict[ip] = -1
    
    powerList = sorted(powerDict.items(), key=lambda d:d[1], reverse = True)
    #write to file
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," begin to write to file ",powerList)
    with open(outputFileName,'w') as f:
        for item in powerList:
            f.write("%s,%s\n"%(item[0],item[1]))

if __name__ == '__main__':
    import sys,time
    minerUser = sys.argv[1]
    print (time.strftime("%Y-%m-%d %H:%M:%S", time.localtime())," miner user is ",minerUser)

    path = os.path.expanduser('~') 
    file_name = path + "/clientData/minerAddress.txt"
    power_name = path + "/clientData/powerRank.txt"
    getMinerPower(minerUser,file_name,power_name)
