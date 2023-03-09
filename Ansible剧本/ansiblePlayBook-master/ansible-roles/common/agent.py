import configparser
import requests
import sys, os, socket, time
import subprocess
try:
    from loguru import logger
except ModuleNotFoundError as e:
    print("要先安装包!!! pip3 install loguru")
    os.system("pip3 install loguru")
finally:
    from loguru import logger

logger.add('/var/log/agent.log', rotation="50 MB")

def runcmd(command):
    ret = subprocess.run(command,shell=True,stdout=subprocess.PIPE,stderr=subprocess.PIPE,encoding="utf-8",timeout=1)
    if ret.returncode == 0:
        #print(ret.stdout)
        logger.info("bin版本获取结果: " + ret.stdout)
        return ret.stdout.split(" ")[2]
    else:
        #print("error:",ret)
        logger.info("bin error: " + ret)

def upload(ipaddress, Component, minerid, binpath, files, change_file_time, version):
    times = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(time.time()))
    hostname = socket.gethostname()
    ip = ipaddress
    nodename=minerid
    role=Component
    data={'times':times, 'hostname':hostname, 'ip':ip, 'nodename':nodename, 'role':role,'files':files, 'version':version, 'change_file_time':change_file_time}
    url = 'http://10.10.8.7:18001/upload2/'
    files = {'my_file': open(files, 'rb')}
    r = requests.post(url, files=files, data=data)
    logger.info("上传状态: %d" % r.status_code)
    #print(r.status_code)

def config_read():
    conf = configparser.ConfigParser()
    conf.read("/root/conf.ini",encoding='utf-8')
    logger.info("正在解析配置文件")
    for item in conf.sections():
        ipaddress = conf.get(item, 'ipaddress')
        Component = conf.get(item, 'Component')
        minerid = conf.get(item, 'minerid')
        binpath = conf.get(item, 'binpath')
        version = runcmd('{0} -version'.format(binpath))
        paths = eval(conf.get(item, 'paths'))
        for files in paths:
            change_file_time = time.strftime('%Y-%m-%d %H:%M:%S',time.localtime(os.path.getmtime(files)))
            upload(ipaddress, Component, minerid, binpath, files, change_file_time, version)


config_read()