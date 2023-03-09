# coding=utf-8
#####   安装依赖库: pip3 install pymysql==0.10.1  -i https://pypi.tuna.tsinghua.edu.cn/simple/
#####   crontab任务设置： 6 */1 * * * cd /home/devnet/joyce; python3 autoGasConfig.py >> autoGasConfig.log
#####                    36 */1 * * * cd /home/devnet/joyce; python3 autoGasConfig.py >> autoGasConfig.log
#####   prove上限是8nano
#####   规则是：
#####   如果节点有8小时过期的扇区数量大于 200个，则prove的basefee取 过去4h 中位数
#####   如果节点有12小时过期的扇区数量大于 200个，但无8小时内过期的扇区，则prove的basefee取 过去4h 中位数*0.9
#####   如果节点有12小时过期的扇区数量小于 200个，则prove的basefee取 24小时的4分位
#####   pre消息的上限是8nano
#####   pre默认取过去24小时的 40%值

import json
import os, sys
import time
from datetime import datetime, timedelta
import requests

def getBaseFeeConfigFromDB():
    import pymysql
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    result = []
    # 执行sql语句
    try:
        with conn.cursor() as cursor:
            sql = "select v25_24h,v33_24h,v40_24h,v25_4h,v50_4h,v66_4h,data_run_time from tr_basefee_avg Order by data_run_time Desc limit 1"
            cursor.execute(sql)
            result=cursor.fetchall()
    finally:
        conn.close()
    #print(result)
    #print(result[0][0])
    print(result[0])
    return result[0][0],result[0][1],result[0][2],result[0][3],result[0][4],result[0][5]

def checkOvertime():
    ## 判断是否有过期的扇区
    cmd_4h="cd ~;~/bin/view_lotus.sh check 4"
    os.popen(cmd_4h)
    time.sleep(10)
    over_4h_num = os.popen("cat ~/over | wc -l").read().rstrip().split("\n")
    print("4小时过期扇区数量: ",over_4h_num[0])

    cmd_6h="cd ~;~/bin/view_lotus.sh check 6"
    os.popen(cmd_6h)
    time.sleep(10)
    over_6h_num = os.popen("cat ~/over | wc -l").read().rstrip().split("\n")
    print("6小时过期扇区数量: ",over_6h_num[0])

    cmd_12h="cd ~;~/bin/view_lotus.sh check 12"
    os.popen(cmd_12h)
    time.sleep(10)
    over_12h_num = os.popen("cat ~/over | wc -l").read().rstrip().split("\n")
    print("12小时过期扇区数量: ",over_12h_num[0])

    return int(over_4h_num[0]),int(over_6h_num[0]),int(over_12h_num[0])

def getSlaveNum():
    cmd="~/bin/lotus-power peers list | grep -v offline | grep git | wc -l"

def getStatusPreCommitting():
    cmd=""" curl -s 127.0.0.1:19402/metrics| grep SectorState|grep -v "#"|awk -F 'SectorState' '{print $2}' | grep PreCommitting | awk '{print $2}' """
    status_PreCommitting = os.popen(cmd).read().rstrip()
    print(status_PreCommitting)
    return int(status_PreCommitting)


def changeConfig(pre,prove):
    pre_n = float(format(pre*1000000000,'.2f'))
    prove_n = float(format(prove*1000000000,'.2f'))

    if(pre_n > 3.6):
        pre_n = 3.6
    if(pre_n < 0.01):
        pre_n = 0.01

    if(prove_n > 3.6):
        prove_n = 3.6
    if(prove_n < 0.01):
        prove_n = 0.01

    cmd = """ cd /home/devnet/.lotusminer; sed -i '/MaxPreCommitBaseFee/ s|".* nfil"|"XXX nfil"|' config.toml; sed -i '/MaxCommitBaseFee/ s|".* nfil"|"YYY nfil"|' config.toml """
    cmd = cmd.replace("XXX",str(pre_n))
    cmd = cmd.replace("YYY",str(prove_n))

    print(cmd)
    os.popen(cmd)

if __name__ == '__main__':
  ######################################
  #minerConfFileList = []

  #首先连接influxdb
  #client = InfluxDBClient(host='10.10.8.7',port=18086,username='',password='',ssl=False,verify_ssl=False,database='lotus')
  print(time.strftime("%Y-%m-%d %H:%M:%S", time.localtime()),"--------------- Start modify basefee config")
  v25_24h,v33_24h,v40_24h,v25_4h,v50_4h,v66_4h = getBaseFeeConfigFromDB()
  #print(type(v25_24h))
  #print(v25_24h)
  over_4h,over_6h,over_12h = checkOvertime()

  getSlaveNum()

  ### 根据过期扇区个数来判断base价格
  prove_fee = v25_4h

  if(over_4h > 100):
    print("prove_fee = v66_4h")
    prove_fee = v66_4h
  elif(over_4h < 100 and over_6h > 100):
    print("prove_fee = v50_4h")
    prove_fee = v50_4h
  elif(over_6h < 100 and over_12h > 100):
    print("prove_fee = v33_24h")
    prove_fee = v33_24h

  precommitting_num = getStatusPreCommitting()
  pre_fee = v25_4h
  if(precommitting_num > 6000):
    print("pre_fee = v66_4h")
    pre_fee = v66_4h
  elif(precommitting_num > 3000):
    print("pre_fee = v50_4h")
    pre_fee = v50_4h

  changeConfig(pre_fee,prove_fee)