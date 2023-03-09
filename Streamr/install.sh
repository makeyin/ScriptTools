#/bin/bash
curl -sSL https://get.daocloud.io/docker | sh   >/dev/null 2>&1
apt update -y >/dev/null 2>&1
apt  install expect gcc make -y   >/dev/null 2>&1
mkdir ~/.streamrDocker

docker pull streamr/broker-node:31.0.0-beta.3  >/dev/null 2>&1


cat >/root/import.sh << EOF
#!/usr/bin/expect
spawn docker run -it -v $(cd ~/.streamrDocker; pwd):/root/.streamr streamr/broker-node:31.0.0-beta.3 bin/config-wizard
expect "import"
send "\r"
expect "information"
send "y\r"
expect "Select the plugins to enable"
send "\r"
expect "staking"
send "Y\r"
expect "config"
send "\r"
expect off
EOF


chmod 777 /root/import.sh 

/root/import.sh  >> info.txt

docker run -itd -p 7170:7170 -p 7171:7171 -p 1883:1883 -v $(cd ~/.streamrDocker; pwd):/root/.streamr streamr/broker-node:31.0.0-beta.3
sleep 30s
docker rm `docker ps -a | grep -vE "Up|CONTAINER" | awk '{print $1}'`
sleep 5s



#!/bin/bash
while true
do
	DocConFai=`docker ps -a| grep -vE "Up|CONTAINER"|wc -l`
	if [ $DocConFai -ne 0 ];then
		docker start `docker ps -a| grep -vE "Up|CONTAINER" | awk '{print $1}'`
	fi
	sleep 45s
done

nohup ~/check.sh  >> ~/check.log 2>&1 &