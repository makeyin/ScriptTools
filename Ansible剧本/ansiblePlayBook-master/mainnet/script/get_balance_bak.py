import requests
import shutil
import datetime
import time
import hashlib
import json
import threading

def getWallet(fileName):
    import os
    walletList = []
    cmd = """ cat %s | awk '{print $1}' """%(fileName)
    walletList = os.popen(cmd).read().rstrip().split("\n")
    #print(walletList)
    return walletList

def getIPList(num):
    pid = "-1"
    cid = "-1"
    unbindTime = "180" ### ip有效时间,单位是秒,3min需要使用完这些IP
    noDuplicate = "1"
    lineSeparator = "0"
    singleIp = "0"
    timeNow = str(int(time.time())) #时间戳
    # 计算sign
    txt = "orderId=" + orderId + "&secret=" + secret + "&time=" + timeNow
    sign = hashlib.md5(txt.encode()).hexdigest()
    # 访问URL获取200个IP
    #url = "http://api.ipproxy.info:8422/api/getIp?type=1&num=" + str(num) + "&pid=" + pid + "&unbindTime=" + unbindTime + "&cid=" + cid +  "&orderId=" + orderId + "&time=" + timeNow + "&sign=" + sign + "&dataType=0&lineSeparator=" + lineSeparator + "&noDuplicate=" + noDuplicate + "&singleIp=" + singleIp
    url="http://api.hailiangip.com:8422/api/getIp?type=1&num=" + str(num) + "&pid=&unbindTime=" + unbindTime + "&cid=&orderId=" + orderId + "&time=" + timeNow + "&sign=" + sign + "&noDuplicate=1&dataType=0&lineSeparator=0&singleIp=0"
    print("url:",url)
    res1 = requests.get(url).content
    #print("-------",res1)
    js_res = json.loads(res1)
    ip_list = js_res["data"]
    # 再发一次URL获取200个IP
    # res2 = requests.get(url).content
    # js_res = json.loads(res2)
    # ip_list += js_res["data"]
    #print(ip_list)
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Get IP number: ",len(ip_list))
    return ip_list

def sendRequest(idx,faucet_url):
    dic = ipList[idx]
    wallet = wallet_list[int(idx/2)]
    ip = dic["ip"]
    port = dic["port"]
    print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Start thread ",idx," using IP: ",ip,", PORT: ",port)
    proxyUrl = "http://" + ip + ":" + str(port)
    proxy = {'http': proxyUrl,"https": proxyUrl}
    params = {"address":wallet,"sectorSize":sectorSize}
    #print(wallet)
    try:
        r1 = requests.get(faucet_url,params=params,proxies=proxy)
        if("200"==str(r1.status_code)):
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " res1 status code : " + str(r1.status_code))
        else:
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " res1 status code : " + str(r1.status_code) + ". Response msg: " + r1.text)
    except requests.exceptions.ConnectTimeout:
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " Connect Timeout!!! Try again..." + ". Response msg: ")
        time.sleep(0.2)
        r2 = requests.get(faucet_url,params=params,proxies=proxy)
        if("200"==str(r2.status_code)):
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " res2 status code : " + str(r2.status_code))
        else:
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " res2 status code : " + str(r2.status_code) + ". Response msg: " + r2.text)
    except requests.exceptions.ConnectionError:
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " Connection Error!!! Try again..." + ". Response msg: ")
        time.sleep(0.2)
        r3 = requests.get(faucet_url,params=params,proxies=proxy)
        if("200"==str(r3.status_code)):
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " res3 status code : " + str(r3.status_code))
        else:
            print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " res3 status code : " + str(r3.status_code) + ". Response msg: " + r3.text)
    except requests.packages.urllib3.exceptions.MaxRetryError:
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " MaxRetry Error!!! Stop thread...")
    except requests.exceptions.ProxyError:
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " Proxy Error!!! Stop thread...")
    except Exception:
        print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"Thread " + str(idx) + " Unknown Error!!! Stop thread...")

if __name__ == '__main__':
    ###订单和密钥
    orderId = "O20040317033276055556"
    secret = "4741801e439c96bc4163e1aca6def39f"
    #############################################################################################
    ################ 抢1475,需要发475*(2/3)个请求(=动态IP的数量)，耗费475*(1/3)个wallet地址
    ################ 动态IP的数量必须是wallet个数的2倍,因为一个wallet要发送2个mkminer请求，占用2个IP
    sectorSize = 34359738368
    #sectorSize = "32GiB"
    #sectorSize = 536870912
    faucetUrl = "https://faucet.calibration.fildev.network/"
    #faucetUrl = "https://faucet.testnet.filecoin.io/mkminer"
    walletFileName = "./key_large.txt"
    #############################################################################################

    walletListTotal = getWallet(walletFileName)
    reqTimes = int(len(walletListTotal)/50)
    ipList = []
    for i in range(0,reqTimes):
        ipList = getIPList(50*2)
        wallet_list=walletListTotal[i*50:(i+1)*50]
        threads=[]
        for i in range(0,len(ipList)):
            t=threading.Thread(target=sendRequest,args=[i,faucetUrl,])
            threads.append(t)
        for t in threads:
            t.start()
            time.sleep(0.3)
        for t in threads:
            t.join()
