import math
import os
from datetime import time, datetime
import time

def get_All_info():
    getAllSectorCmd="""sed -n '$p' ~/bin/query.txt |awk '{print $2}'"""
    getMinerIdCmd=""" ~/bin/lotus-window info | grep 'Miner:' | awk '{print $NF}'"""
    getQuerySectorCmd="""~/bin/lotus-window sector query > ~/bin/query.txt"""
    getisuploadsCmd="""sed -n '$p' ~/bin/query.txt |awk '{print $4}'"""
    getUploadSlaveCmd="""grep "isFinish:false" ~/bin/query.txt  | wc -l"""
    getisFinishCmd="""grep "isUpload: false" ~/bin/query.txt  | wc -l"""
    os.popen(getQuerySectorCmd).read().rstrip()
    selfMinerId = os.popen(getMinerIdCmd).read().rstrip()
    time.sleep(5)
    getAllSector = os.popen(getAllSectorCmd).read().rstrip()
    getisuploads = os.popen(getisuploadsCmd).read().rstrip()
    getUploadSlave = os.popen(getUploadSlaveCmd).read().rstrip()
    getisFinish = os.popen(getisFinishCmd).read().rstrip()
    data_Time = datetime.now().strftime("%Y-%m-%dT%H:%M:%S")
    data_result={"minerID":selfMinerId,"AllSector":getAllSector,"isuploads":getisuploads,"UploadSlave":getUploadSlave,"isFinish":getisFinish,"dataTime":data_Time}
    return data_result

def get_two_float(f_str, n):
    f_str = str(f_str) # f_str = '{}'.format(f_str)
    a, b, c = f_str.partition('.')
    c = (c+"0"*n)[:n]
    return ".".join([a, c])

def DataToDB(data_dict):
    print(data_dict)
    import pymysql
    conn = pymysql.connect('10.10.8.7', user="root", passwd="L3xyA7N4WcoKMCSd", db="data_center")
    tableName = "tr_upload_qiniu"
    cur = conn.cursor()

    sql = "insert into tr_upload_qiniu values(%s,%s,%s,%s,%s,%s,%s,%s)"

    cur.execute(sql, (
        data_dict["date_run_time"],
        data_dict["miner_id"],
        data_dict["customer_name"],
        data_dict["sectors_all_count"],
        data_dict["uploads_count"],
        data_dict["notupload_count"],
        data_dict["notupload_slave_count"],
        data_dict["proportion"],
    ))
    conn.commit()
    cur.close()
    conn.close()

def transfer_data(data):
    try:
        import requests, traceback
        url = 'http://39.170.24.100:18701/qiniu/'
        r = requests.post(url, data=data)
        print("请求状态: %d,数上传成功" % r.status_code)
    except:
        print(traceback.format_exc())


if __name__ == '__main__':
    dbDataDict = {}
    DictMinerName = {"f01475": "qdh_1475",
                     "f014386": "qdh_1475",
                     "f020618": "qdh_1475",
                     "f020452": "qdh_1475",
                     "f021461": "1475",
                     "f021547": "qdh_1475",
                     "f045756": "qdh_1475",
                     "f061051": "qdh_矿无界",
                     "f065881": "qdh_熵",
                     "f079815": "qdh_火星云矿",
                     "f086240": "qdh_Karl",
                     "f087256": "qdh_蝶恋科技",
                     "f089551": "qdh_奶牛",
                     "f096172": "qdh_北京三人组",
                     "f0103665": "qdh_思密达",
                     "f01314": "qdh_基金",
                     "f0110996": "qdh_蝶链2号",
                     "f0111007": "qdh_股东福利",
                     "f0121584": "qdh_储备节点1",
                     "f0118641": "qdh_熵2",
                     "f030408": "三号矿场",
                     "f022804": "星际公链",
                     "f029665": "沈阳区块链",
                     "f021961": "熊猫",
					 "f0122940": "熊猫2号",
                     "f023882": "矿无界",
                     "f030408": "三号矿场"}

    info=get_All_info()
    dbDataDict["miner_id"] = info["minerID"]
    dbDataDict["customer_name"] = DictMinerName[dbDataDict["miner_id"]]
    dbDataDict["sectors_all_count"] = int(info["AllSector"])
    dbDataDict["date_run_time"] = info["dataTime"]
    dbDataDict["uploads_count"] = int(info["isuploads"])
    dbDataDict["notupload_slave_count"] = int(info["UploadSlave"])
    dbDataDict["notupload_count"] = int(info["isFinish"])
    fload_data=(int(info["isuploads"])/int(info["AllSector"]))*100
    fload_data_two=get_two_float(fload_data, 2)
    dbDataDict["proportion"] = '%s%%'%fload_data_two
    if("qdh" in dbDataDict["customer_name"] ):
        DataToDB(dbDataDict)
    else:
        transfer_data(dbDataDict)