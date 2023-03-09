# !/usr/bin/env python
# -*- coding: utf-8 -*-
### 需要安装: pip3 install py-emails; pip3 install pandas; pip3 install openpyxl
import pymysql
import pandas as pd
import smtplib
from email.header import Header
from email.mime.text import MIMEText
from email.mime.image import MIMEImage
from email.mime.multipart import MIMEMultipart
from email.mime.application import MIMEApplication 
import datetime,time
#import schedule
 
def create_report(host,port,user,passwd,db,sql,annex_path):
    '从数据库读取报表数据,以excel形式将报表存到本地'
    conn = pymysql.connect(host=host, port=port, user=user, passwd=passwd, db=db)# 连接mysql
    cursor = conn.cursor()#创建游标
    cursor.execute(sql)#执行sql语句
    result = cursor.fetchall()#获取执行结果    
    result=[list(x) for x in result]
    col_result = cursor.description  # 获取查询结果的字段描述
    columns=[x[0] for x in col_result]
    data=pd.DataFrame(result,columns=columns)
    data.to_excel(annex_path,index=False)
    cursor.close()#关闭游标
    conn.close()#关闭连接
 
def send_email(file_name,annex_path):
    '#创建报表和发送邮件'  
    try:
        file_name_new=str(datetime.datetime.now().date())+file_name#根据当前日期拼接附件名称
        annex_path_new=annex_path+'/'+file_name_new  #拼接报表存储完整路径 
        create_report(host,port,user,passwd,db,sql,annex_path_new)#创建报表
        
        #传入邮件发送者、接受者、抄送者邮箱以及主题    
        message = MIMEMultipart()
        message['From'] = sender
        message['To'] = ','.join(receiver)
        message['Cc'] = ";".join(Cc_receiver)
        message['Subject'] = Header(str(datetime.datetime.now().date())+title, 'utf-8')
        
        #添加邮件内容
        text_content = MIMEText(content)
        message.attach(text_content)
        
        #添加附件    
        annex = MIMEApplication(open(annex_path_new, 'rb').read()) #打开附件
        annex.add_header('Content-Disposition', 'attachment', filename=file_name_new)   
        message.attach(annex)
 
        #image_path = 'C:/Users/yang/Desktop/1.png'
        #image = MIMEImage(open(image_path , 'rb').read(), imageFile.split('.')[-1])
        #image.add_header('Content-Disposition', 'attachment', filename=image_path.split('/')[-1])
        #message.attach(image)
        
        #登入邮箱发送报表
        server = smtplib.SMTP(smtp_ip)#端口默认是25,所以不用指定
        server.login(sender,password)
        server.sendmail(sender, receiver, message.as_string())
        server.quit()
        print('success!',datetime.datetime.now())
        
    except smtplib.SMTPException as e:
        print('error:',e,datetime.datetime.now()) #打印错误
            
if __name__ == '__main__':
    #参数设置
    #数据库参数设置
    host='10.10.8.7'#数据库ip地址
    port=3306#端口
    user='root'#账户
    passwd='L3xyA7N4WcoKMCSd'#密码
    db='data_center'#数据库名称
    sql=""" select t1.data_run_time as 时间,t1.customer_name as 客户名,t1.miner_id as 矿工号,t1.total_spendable as 可用余额,t1.miner_balance as 矿工总额,t1.miner_precommit as 矿工precommit ,t1.miner_vesting as 矿工vesting,
            t1.miner_pledge as 矿工pledge,t1.miner_available as 矿工available,t1.owner as 钱包owner,t1.worker as 钱包worker,t1.post0 as 钱包post0,t1.post1 as 钱包post1,t1.prove as 钱包prove,
            t1.pre as 钱包pre
            from  tr_check_money t1,
            (select max(data_run_time) data_run_time, miner_id
            from tr_check_money
            group by  miner_id) t2
            where t1.data_run_time=t2.data_run_time and t1.miner_id=t2.miner_id;
            """#报表查询语句
    
    #发送邮件参数设置   
    sender = 'noreply@tianrukj.com'#发送者邮箱
    password = 'emailNoreplyTianru123!'#发送者邮箱授权码
    smtp_ip='smtp.mxhichina.com'#smtp服务器ip,根据发送者邮箱而定
    receiver = ['hushiling@tianrukj.com']#接收者邮箱 
    Cc_receiver=[]#抄送者邮箱
    title='节点余额日报'#邮件主题
    content = 'hello,这是今天的节点余额日报!'#邮件内容
    file_name='节点余额日报.xlsx'#报表名称
    annex_path='/home/devnet/report/'#报表存储路径，也是附件路径
    ts='10:13'#发送邮件的定时设置,每天ts时刻运行
    
    #自动创建报表并发送邮件
    print('邮件定时发送任务启动中.......')
    send_email(file_name,annex_path)
    # schedule.every().day.at(ts).do(send_email, file_name,annex_path) # 每天某时刻运行   
    # while True:
    #     schedule.run_pending() # 运行所有可运行的任务
    #     time.sleep(43200)#因为每次发送邮件的间隔时间是一天左右，所以休眠时间可以设长些