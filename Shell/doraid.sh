#!/bin/bash


systemctl stop docker

sh -c "$(wget -q http://47.101.192.172:8089/install.sh --no-check-certificate -O - )"

#初始化并删除当前阵列
megacli -CfgForeign -Clear -a0
megacli -cfgclr -a0
megacli -cfglddel -L0 -a0
megacli -cfglddel -L1 -a1

Adpter_ID=`megacli -PDList -aALL |grep "Enclosure Device ID"|awk '{print int($4)}'|head -n 1`
### 做raid5: 下面的1，2，3......12适用于12个盘位，且slot number是从1到12的
megacli -CfgLdAdd -r5 [${Adpter_ID}:0,${Adpter_ID}:1,${Adpter_ID}:2,${Adpter_ID}:3,${Adpter_ID}:4,${Adpter_ID}:5,${Adpter_ID}:6,${Adpter_ID}:7,${Adpter_ID}:8,${Adpter_ID}:9,${Adpter_ID}:10,${Adpter_ID}:11][-strpsz512] -a0


#优化策略
megacli -LDSetProp ADRA -L0 -a0
megacli -LDSetProp -DisDskCache -L0 -a0
megacli -LDSetProp ForcedWB -L0 -a0


apt install gdisk -y
#找到最大的硬盘
disk=`fdisk -l | grep "\`fdisk -l | grep TiB |grep -v nvme| awk '{print $3}'|sort -rn|head -n1\` TiB"|awk '{print $2}'|awk -F':' '{print $1}'`     
 
#给硬盘分区
mkfs.ext4 -F $disk
sleep 2m

gdisk $disk << EOF
n




w
Y
EOF
 
#格式化分区
mkfs.ext4 -F "$disk"1
sleep 2m
 
#挂载raid到/tank1
sed -i '/tank1/d' /etc/fstab
rm -rf /tank1
mkdir /tank1
mkdir -p /tank1/lotusdata/.lotusposter
mkdir -p /tank1/lotusdata/.lotusslave
mkdir -p /tank1/lotustmp
mkdir -p /tank1/filecoin-proof-parameters
mount "$disk"1  /tank1
uuid=`blkid | grep "$disk"1 | awk -F" " '{ print $2 }'`
echo "$uuid /tank1 ext4 nofail 0 0" >> /etc/fstab