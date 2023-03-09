#!/bin/bash
count=1
arr=`lsblk |grep disk |grep -w "..\..T" | awk -F "[ ]+" '{print $1}' |grep -v NAME |grep -v nvme`

for i in $arr
do
uuid=`blkid | grep /dev/$i | awk -F" " '{ print $2 }'`
mkfs.ext4 -F "/dev/"$i
mkdir "/subdata"$count
mount "/dev/"$i "/subdata"$count
echo "$uuid /subdata$count ext4 nofail  0 0" >> /etc/fstab
count=$(($count+1))
done




#获取UUID
uuid=`blkid | grep $i | awk -F" " '{ print $2 }'`
#添加UUID开机自动挂载
echo "$uuid /data1 ext4 nofail 0 0" >> /etc/fstab
