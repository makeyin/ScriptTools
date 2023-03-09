# -*- coding: utf-8 -*-
"""
Created on Sun Nov  8 17:57:17 2020

@author: ASUS
"""

import pandas as pd
import datetime
from bs4 import BeautifulSoup
import openpyxl
import requests
import time
from threading import Timer

class MyTimer( object ):
    def __init__( self,start_time,interval, callback_proc, args=[], kwargs={} ):
        self.__interval = interval
        self.__start_time = start_time
        self.__callback_pro = callback_proc
        self.__args = args
        self.__kwargs = kwargs

    def exec_callback( self, args=[], kwargs={} ):
        self.__callback_pro( *self.__args, **self.__kwargs )
        every_interval = self.__interval - (datetime.datetime.now().timestamp() - datetime.datetime.now().replace( minute=0, second=0, microsecond=0 ).timestamp())
        self.__timer = Timer( every_interval, self.exec_callback )
        self.__timer.start()

    def start( self ):
        start_interval = self.__interval - (datetime.datetime.now().timestamp() - self.__start_time.timestamp())
        self.__timer = Timer(0, self.exec_callback )
        self.__timer.start()
######爬虫
def yu_e():
    ######获取last数据
    df_time = pd.read_excel('C:\\Users\\lege\\Desktop\\1475\\上次更新时间(客户).xlsx')
    time1 = df_time.iloc[0,0]   
    sheet_name = str(time1)
    df_last = pd.read_excel('C:\\Users\\lege\\Desktop\\1475\\客户余额表.xlsx',sheet_name=sheet_name)
    df_last = df_last.set_index(['节点号'])
    df_last = df_last.drop('总计',axis=0,inplace=False)
    now_time = datetime.datetime.now().strftime('%H:%M')
    headers = {
                'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/86.0.4240.183 Safari/537.36',
                'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8,application/signed-exchange;v=b3;q=0.9',
                'Accept-Language' : 'zh-CN,zh;q=0.9,en;q=0.8',
                'Accept-Encoding' : 'gzip, deflate, br',
                'Connection' : 'keep-alive'
}


    list = {
        'f021961':'t3vxqrs6prxxahvl55sgpulaszp6p5o6wk6ddih4nmstfyfob4ytpimjct6ul7j6znd67vtnwsdtjnldc72e4q',
        'f029665':'t3wlpcv55fdw3opetk2xjd26uux2zczbsb6m7u52gdkiaio4xvg2qzearnfpn7fggq5adawnsr24tlm2qxbgia',
        'f021536':'t3shhfnkmar43s2lik7vvps6nod5som6nln5zoxehshgbhz6kcy35dzclfq4rgjsugy7cpvkmff5x4bgquexaq',       
        'f023882':'t3ry6ahntg42zxsjmbwormuvkri65xvx4iyfijbwrox4c4kpebep4vhmnxyn7bbxyr7jcvw6nocun4v7buubjq',   
        'f022804':'t3tfi2wsl6cuar77oto6nsxnv4qldemxf4tuz3f7q35hrx6tvjpmuc62ab2qzfnustb4ux43cl2zcxgomr65wq',
        'f030408':'t3wfjtbquwkqjzcs57pgw36bn66ktourzfmntcgtdcrhad2lnmsfuhpu72eluhchtoie7a52ftrymmvjiafgyq',
        'f065881':'f3q2uu5w3a6nkcm3e5bnca35dfvxpmwvexth6tjkcpfftmowmkaus3kzbikiirhk2i24ogm72yijguj4ptgkfa',
        'f061051':'f3r4usv3vdaovhzybs3xz7spczyoyhxtkgps4wtxmpx7wzufcs5vb225yza4sm4mta5t7ringpay5rgbouuw2a',
        'f079815':'f3qrmmeoi7c3fcoerfmtdw33hc7c4z3kct52qpwp6p4i7xn4xecalj23w7pj3opmcvzoez23el6l7kk2iii6la',
        'f087256':'f3rp34xonsck2yilj2lypw6szjmgy4sx6cmogarnvidv6o2s2fiowkitfsweg77hj53h3f3b2qzun4ams3qvwa',
        'f086240':'f3ssg7tdz3mucs37ckfuug6kex4eu6g33575xu3tkwimurkot7ew3ddviqwwjhulqxdfppw6m7cvkq5a7oufuq',
        'f089551':'f3w2t7neo6vfdh44akq2637x54bh5o6eue5kernlb53dkv4pqhhz7kmtbm5o7zlwmlkp2m7frsnqjjy5k5a7ja',
        'f0103665':'f3xctlxgs6m6d6eopg647lchng3wxbffpv34wsdn4vadwpscwcje47lmgqy7u4yatfy6favv5kd7qpgoze44va',
        'f0110996':'f3rih6uwqegqqvolu3kmfx4dk4y3iopo4ltj6i3wzphfmwbk6qvnw3fh53guhs6nycbtgp7dv47giwz6ldyifa',
         }

    mymap={
        'f021961':'熊猫',
        'f029665':'沈阳',
        'f021536':'星际存储',       
        'f023882':'矿无界',   
        'f022804':'公链',
        'f030408':'三号',
        'f065881':'熵',
        'f061051':'G-XJCC',
        'f079815':'火星',
        'f087256':'蝶恋',
        'f086240':'Karl',
        'f089551':'奶牛',
        'f0103665':'欧巴',
        'f0110996':'蝶链二号',
       }

    result = []

    i = 'f023499'
    for i in list:
        item = dict()
        x = list[i]
        while True:
            res = requests.get('https://filfox.info/zh/address/%s' % i, headers=headers)
            if (res.status_code == 200):
                break
            else:
                time.sleep(1)
        while True:
            res1 = requests.get('https://filfox.info/zh/address/%s' % x, headers=headers)
            if (res1.status_code == 200):
                break
            else:
                time.sleep(1)        
        bs = BeautifulSoup(res.text,'html.parser')
        bs1 = BeautifulSoup(res1.text,'html.parser')
        item['时间'] = now_time
        item['客户名'] = mymap[i]
        item['节点号'] = i
        g = bs.find_all('p',class_="text-xs")[8].text.split(' ')[2]
        h = bs.find_all('p',class_="text-xs text-gray-800")[12].text.split(' ')[2]
        if g =='PiB':
            item['算力(TiB)'] = float(bs.find_all('p',class_="text-xs")[8].text.split(' ')[1]) * 1024
        elif g =='GiB':
            item['算力(TiB)'] = float(bs.find_all('p',class_="text-xs")[8].text.split(' ')[1]) / 1024
        elif g =='TiB':
            item['算力(TiB)'] = float(bs.find_all('p',class_="text-xs")[8].text.split(' ')[1])
        elif g == 'B':
            item['算力(TiB)'] = float(bs.find_all('p',class_="text-xs")[8].text.split(' ')[1]) / 1024 / 1024 / 1024 / 1024
        elif g == 'MiB':
            item['算力(TiB)'] = float(bs.find_all('p',class_="text-xs")[8].text.split(' ')[1]) / 1024 / 1024
        item['算力(PB)'] = bs.find_all('p',class_="text-xs")[8].text.replace(' PiB ','')
        item['占比(%)'] = bs.find_all('p',class_="text-xs")[5].text.replace(' 占比: ', '').replace('% ','')
        item['累计出块份数'] = bs.find_all('p',class_="text-xs text-gray-800")[3].text.replace(' ', '')
        item['累计出块奖励'] = bs.find_all('p',class_="text-xs text-gray-800")[5].text.replace(' ', '').replace('FIL','').replace(',','')
        if h == 'B':
            item['算力增速(TiB/天)'] = float(bs.find_all('p',class_="text-xs text-gray-800")[12].text.strip().split(' ')[0]) / 1024 / 1024 / 1024
        elif h == 'GiB':
            item['算力增速(TiB/天)'] = float(bs.find_all('p',class_="text-xs text-gray-800")[12].text.strip().split(' ')[0]) / 1024
        elif h == 'TiB':
            item['算力增速(TiB/天)'] = float(bs.find_all('p',class_="text-xs text-gray-800")[12].text.strip().split(' ')[0])
        elif h == 'PiB':
            item['算力增速(TiB/天)'] = float(bs.find_all('p',class_="text-xs text-gray-800")[12].text.strip().split(' ')[0]) * 1024            
        item['账户总余额'] = bs.find_all('p',class_="font-medium text-2xl")[0].text.replace(' ', '').replace('FIL','').replace(',','')
        item['抵押金额'] = bs.find_all('p',class_='text-xs mt-1 text-gray-800')[0].text.replace(' 扇区抵押: ', '').replace(' FIL ','').replace(',','')
       ## item['可用余额'] = bs.find_all('p',class_='text-sm mt-4')[1].text.replace(' 可用余额: ', '').replace(' FIL ','').replace(',','')
        item['可用余额'] = bs.find_all('p',class_='text-xs mt-3 text-gray-800')[0].text.replace(' 可用余额: ', '').replace(' FIL ','').replace(',','')
        item['Worker'] = bs1.find_all('p',class_="flex w-3/4")[1].text.replace(' ', '').replace('FIL','').replace(',','')
        item['幸运值(%)'] = bs.find_all('div',class_="text-sm w-1/6 text-right flex flex-row items-center justify-end")[0].text.replace(' 幸运值 实际爆块数量和理论爆块数量的比值。若矿工有效算力低于1PiB，则该值存在较大随机性，仅供参考。 : ','').replace('%','')
        item['24小时奖励'] = bs.find_all('p',class_="text-xs text-gray-800")[16].text.replace(' ', '').replace('FIL','').replace(',','')
    
        item['全部扇区'] = bs.find('div',class_='text-xs text-gray-800 text-right w-3/4').select('span')[0].text.replace(' ', '').replace('全部,','').replace(',','')
        item['有效'] = bs.find('div',class_='text-xs text-gray-800 text-right w-3/4').select('span')[1].text.replace(' ', '').replace('有效,','').replace(',','')
        item['错误'] = bs.find('div',class_='text-xs text-gray-800 text-right w-3/4').select('span')[2].text.replace(' ', '').replace('错误,','').replace(',','')
        item['恢复中'] = bs.find('div',class_='text-xs text-gray-800 text-right w-3/4').select('span')[3].text.replace(' ', '').replace('恢复中','').replace(',','')
        result.append(item)
        print('%s读取成功'%i)
    print('------------------客户节点读取成功')

######数据清洗
    global df_kehu
    df_kehu = pd.DataFrame(result)
    order = ['客户名','时间','节点号','幸运值(%)','算力(TiB)','占比(%)','算力增速(TiB/天)','累计出块份数','累计出块奖励','24小时奖励',
         '账户总余额','可用余额','抵押金额','Worker','全部扇区','有效','错误','恢复中']
    df_kehu = df_kehu[order]
    df_kehu = df_kehu.set_index(['节点号'])
    colums_name = df_kehu.columns.values
    for i in colums_name:
        if i == '节点号'or i == '时间'or i =='客户名' or i == '算力':
            pass
        else:
            df_kehu[[i]] = df_kehu[[i]].astype(float)
    lucky_mean = df_kehu['幸运值(%)'].mean()

    ######   计算增速
    for i in df_kehu.index:
        if i not in df_last.index:
            df_last.loc[i]=[0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
    df_kehu['幸运值增量'] = df_kehu['幸运值(%)'] - df_last['幸运值(%)'] 
   ## df_kehu['算力增速增量'] = df_kehu['算力增速(TiB/天)'] - df_last['算力增速(TiB/天)']
    df_kehu['出块增量'] = df_kehu['累计出块份数'] - df_last['累计出块份数']
    df_kehu['收益增量'] = df_kehu['累计出块奖励'] - df_last['累计出块奖励']
    df_kehu['错误增量'] = df_kehu['错误'] - df_last['错误']    
                                             
    df_kehu.loc['总计'] = df_kehu.apply(lambda x: x.sum())    
    df_kehu.at['总计','时间'] = now_time
    df_kehu.at['总计','幸运值(%)'] = lucky_mean
    df_kehu.at['总计','客户名'] = '客户总计'
    
    
    #df_kehu['区间'] = (pd.to_datetime(df_kehu['时间']) - pd.to_datetime(df_last['时间'])).dt.total_seconds() / 60
    order = ['客户名','时间','幸运值(%)','幸运值增量','算力(TiB)','占比(%)','算力增速(TiB/天)',
         '出块增量','收益增量','24小时奖励','累计出块份数','累计出块奖励',
         '账户总余额','可用余额','抵押金额','Worker','全部扇区','有效','错误','恢复中','错误增量']
    df_kehu = df_kehu[order]

#######更新时间保存
    detail_time = datetime.datetime.now().strftime('%Y/%m/%d/%H:%M')
    detail_time = detail_time.replace('/','年').replace('/','月').replace('/','日').replace(':','点') + '分'
    df_time = pd.DataFrame([{'时间':detail_time}])
    df_time.to_excel('E:\\Myself\\osp123\\上次更新时间(客户).xlsx',index=None)

#####保存数据
    name = detail_time
    writer = pd.ExcelWriter('E:\\Myself\\osp123\\客户余额表.xlsx',engine='openpyxl')
    book = openpyxl.load_workbook(writer.path)
    writer.book = book
    df_kehu.to_excel(writer, name)
    writer.save()

start_time = datetime.datetime.now().replace( minute=0, second=0, microsecond=0 )
time_inter = 60*60   #间隔时间检测一次,原定1小时，
tmr = MyTimer(start_time,time_inter, yu_e)
tmr.start()