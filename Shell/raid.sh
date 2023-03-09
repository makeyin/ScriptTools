sudo megacli -CfgForeign -Clear -a0
sudo megacli -cfgclr -a0 
Adpter_ID=`megacli -PDList -aALL |grep "Enclosure Device ID"|awk '{print int($4)}'|head -n 1`
megacli -CfgLdAdd -r0 [${Adpter_ID}:0,${Adpter_ID}:1,${Adpter_ID}:2,${Adpter_ID}:3,${Adpter_ID}:4,${Adpter_ID}:5,${Adpter_ID}:6,${Adpter_ID}:7,${Adpter_ID}:8,${Adpter_ID}:9,${Adpter_ID}:10,${Adpter_ID}:11] [-strpsz512] -a0
megacli -LDSetProp RA -L0 -a0 
megacli -LDSetProp -DisDskCache -L0 -a0 
megacli -LDSetProp ForcedWB -L0 -a0 
sleep 10
mkfs.ext4 -F /dev/sda
mkdir /tank1
mount /dev/sda /tank1
echo "/dev/sda /tank1 ext4 defaults,nofail,discard 0 0">>/etc/fstab
2.fdisk -l 找到60T的虚拟硬盘对应的/dev/sdb
tank3=` fdisk -l |grep "/dev/nvme" |grep "953.9 GiB" |awk -F '/dev/' '{print $2}'|awk -F ':' '{print $1}'|awk '{print $1}'|sed -n '1p'`
tank4=` fdisk -l |grep "/dev/nvme" |grep "953.9 GiB" |awk -F '/dev/' '{print $2}'|awk -F ':' '{print $1}'|awk '{print $1}'|sed -n '2p' `
mkfs.ext4 -F /dev/$tank3
mkfs.ext4 -F /dev/$tank4
mkdir /tank3 /tank4
sleep 2
mount /dev/$tank3 /tank3
mount /dev/$tank4 /tank4
tank3uid=`ls -al /dev/disk/by-uuid/ |grep "$tank3" |awk '{print $9}'`
tank4uid=`ls -al /dev/disk/by-uuid/ |grep $tank4 |awk '{print $9}'`
echo "UUID=$tank3uid /tank3 ext4 defaults,nofail,discard 0 0" >>/etc/fstab
echo "UUID=$tank4uid /tank4 ext4 defaults,nofail,discard 0 0" >>/etc/fstab