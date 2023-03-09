import requests
from retrying import retry
import random
import re
from datetime import datetime, timedelta
import os
from bs4 import BeautifulSoup
import requests
@retry(stop_max_attempt_number=1000,wait_incrementing_increment=100)
def get_All_power():
    agent_list=["Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.3; .NET4.0C; .NET4.0E) QQBrowser/6.9.11079.201","Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.3 (KHTML, like Gecko) Chrome/6.0.472.33 Safari/534.3 SE 2.X MetaSr 1.0","Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.3; .NET4.0C; .NET4.0E)","Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0; .NET CLR 2.0.50727; SLCC2; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.3; .NET4.0C; Tablet PC 2.0; .NET4.0E)","Opera/9.80 (Windows NT 6.1; U; zh-cn) Presto/2.9.168 Version/11.50","Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0) Gecko/20100101 Firefox/6.0","Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.163 Safari/535.1"]
    agent = random.choice(agent_list)
    headers = {
        'user-agent': '%s'%agent}
    url = 'https://filfox.info/zh'
    response = requests.get(url, headers=headers).content.decode('utf-8')
    html = BeautifulSoup(response, 'html.parser')
    text = html.body.div.text
    if "Server error" in html.text:
        raise Exception('服务器有点问题')
    text_list = str(text).split(" ")
    result = text_list[59], text_list[60]
    all_power = str(result).replace(',', "").replace(' ', "").replace("'", '')

    return all_power[1:-1]

@retry(stop_max_attempt_number=1000,wait_incrementing_increment=100)
def get_Lucky(minet_id):
    agent_list=["Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.3; .NET4.0C; .NET4.0E) QQBrowser/6.9.11079.201","Mozilla/5.0 (Windows; U; Windows NT 6.1; en-US) AppleWebKit/534.3 (KHTML, like Gecko) Chrome/6.0.472.33 Safari/534.3 SE 2.X MetaSr 1.0","Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 6.1; WOW64; Trident/5.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.3; .NET4.0C; .NET4.0E)","Mozilla/5.0 (compatible; MSIE 9.0; Windows NT 6.1; Win64; x64; Trident/5.0; .NET CLR 2.0.50727; SLCC2; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; InfoPath.3; .NET4.0C; Tablet PC 2.0; .NET4.0E)","Opera/9.80 (Windows NT 6.1; U; zh-cn) Presto/2.9.168 Version/11.50","Mozilla/5.0 (Windows NT 6.1; WOW64; rv:6.0) Gecko/20100101 Firefox/6.0","Mozilla/5.0 (Windows NT 6.1; WOW64) AppleWebKit/535.1 (KHTML, like Gecko) Chrome/14.0.835.163 Safari/535.1"]
    agent = random.choice(agent_list)
    headers = {
        'user-agent': '%s'%agent}
    url = 'https://filfox.info/zh/address/%s' % minet_id

    response = requests.get(url, headers=headers).content.decode('utf-8')
    html = BeautifulSoup(response, 'html.parser')
    text = html.body.div.text
    if "Server error" in html.text:
        raise Exception('服务器有点问题')
    text_list = str(text).split(":")
    Rate_power=(text_list[5].split(" ")[1])[:-1]

    result_Lucky = float(((text_list[20].split(" "))[1])[:-1])
    result_power = text_list[4].split(" ")
    powerNum = str(result_power[6:-2]).replace(',', '').replace("'", '').replace(" ", '')
    power=powerNum[1:-1]
    powers=float((powerNum[1:-1])[:-3])
    if power[-3:] =="TiB":
        powers=float(power[:-3])/1024
    data_result=[result_Lucky,round(powers, 2),Rate_power]
    return data_result


def get_Info():
    #selfMinerId = os.popen("~/bin/lotus-winning info | grep 'Miner:' | awk '{print $NF}'").read().rstrip()
    data_Time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    dataInfo={"dataTime":data_Time}
    return dataInfo


def saveWinningDataToDB(data_dict):
    print(data_dict)
    import pymysql
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    tableName = "tr_winning_data"
    cur = conn.cursor()

    sql = "insert into miner_lucky_value_statistics values(%s,%s,%s,%s,%s,%s,%s,%s,%s,%s)"

    cur.execute(sql, (
        data_dict["date_run_time"],
        data_dict["miner_id"],
        data_dict["customer_name"],
        data_dict["miner_power"],
        data_dict["net_power"],
        data_dict["rate"],
        data_dict["miner_power_900"],
        data_dict["net_power_900"],
        data_dict["rate_900"],
        data_dict["lucky_filfox"]
    ))

    conn.commit()
    cur.close()
    conn.close()



if __name__ == '__main__':
    dbDataDict = {}
    DictMinerName = {"f01475": "1475",
                     "f014386": "1475",
                     "f020618": "1475",
                     "f020452": "1475",
                     "f021461": "1475",
                     "f021547": "1475",
                     "f045756": "1475",
                     "f061051": "矿无界",
                     "f065881": "熵",
                     "f079815": "火星云矿",
                     "f086240": "Karl",
                     "f087256": "蝶恋科技",
                     "f089551": "奶牛",
                     "f096172": "北京三人组",
                     "f0103665": "欧巴-思密达",
                     "f030408": "三号矿场",
                     "f022804": "星际公链",
                     "f029665": "阳区块链",
                     "f021961": "熊猫",
                     "f023882": "矿无界",
                     "f023499": "赛道",
                     "f02770": "时空云&灵动",
                     "f01248": "智合云(ZH)",
                     "f09652": "RRmine.com",
                     "f025002": "ipfs.so(合盈)",
                     "f023530": "星际矿池-天秤座",
                     "f01782": "hellofil.com",
                     "f09037": "星际大陆",
                     "f02438": "原力区",
                     "f01235": "星际大陆",
                     "f02303": "鑫兜科技",
                     "f049911": "麦客存储为您服务",
                     "f024563": "蝶链科技",
                     "f02775": "时空云&灵动",
                     "f020330": "ipfs.so(合盈)",
                     "f022373": "星际大陆",
                     "f02520": "先河",
                     "f023627": "星际大陆",
                     "f022374": "星际大陆",
                     "f01272": "储迅",
                     "f02528": "星际云库",
                     "f023205": "--",
                     "f01012": "蛮牛科技",
                     "f02626": "先东科技",
                     "f021479": "星际矿池-双鱼座",
                     "f030347": "--",
                     "f021525": "KJS—lianzheng",
                     "f02416":"星际无限",
                     "f035364": "HashCow",
                     "f023626": "星际大陆",
                     "f040665": "--",
                     "f01231": "星际矿池-金牛座",
                     "f039992": "雅典娜云池",
                     "f082095": "--",
                     "f03176": "Five Star-Helmsman&Heiben",
                     "f086204": "点存-木星",
                     "f02731": "瓜子���机",
                     "f073525": "--",
                     "f02614": "RRmine.com",
                     "f020331": "逆熵-π",
                     "f091143": "--",
                     "f094003": "--",
                     "f092228": "--",
                     "f060805": "DataLineKR",
                     "f024137": "--",
                     "f066102": "联盟矿池-Hotbit",
                     "f047857": "星河云储",
                     "f01314":"基金",
                     "f0110996":"蝶链(new)",
                     "f021536":"星际存储",
                     "f0121584":"储备节点",
                     "f0132638":"64G宝贝",
                     "f0133376":"熵-3",
                     "f0111007": "股东福利"}
    for key in DictMinerName.keys():
        minerID=key
        if minerID == "":
            exit(0)
        selfMinerId = get_Info()
        allPower=get_All_power()
        minerName = DictMinerName[minerID]
        Lucky_value = get_Lucky(str(minerID))
        dbDataDict["date_run_time"] = str(selfMinerId["dataTime"])
        dbDataDict["miner_id"]=str(minerID)
        dbDataDict["customer_name"] = str(minerName)
        dbDataDict["miner_power"] = Lucky_value[1]
        dbDataDict["net_power"] = allPower
        dbDataDict["rate"] = Lucky_value[2]
        dbDataDict["miner_power_900"] = -1
        dbDataDict["net_power_900"] = -1
        dbDataDict["rate_900"] = -1
        dbDataDict["lucky_filfox"] = Lucky_value[0]
        saveWinningDataToDB(dbDataDict)