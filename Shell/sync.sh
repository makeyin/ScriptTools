#!/bin/sh
/usr/local/inotify/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w %f %e' -e modify,delete,create,attrib /tmp/test/ \
| while read file
do
rsync -avzuP --delete /tmp/test/ root@192.168.192.136:/tmp/test/
echo "${file}" >>/var/log/rsyncd.log 2>&1
done
exit 0

```
使用rsync和inotify

1,两台机器配置免密登录
2,ssh-keygen
ssh-copy-id -i ~/.ssh/id_rsa.pub root@192.168.192.135
3,下载rsync
yum install rsync -y
4,启动 rsync
systemctl start rsyncd
5,安装inotify
(1)wget http://github.com/downloads/rvoicilas/inotify-tools/inotify-tools-3.14.tar.gz
(2)tar zxvf inotify-tools-3.14.tar.gz
(3)cd inotify-tools-3.14
(4)yum -y install gcc
(5)mkdir /usr/local/inotify
(6)./configure --prefix=/usr/local/inotify
(7)make && make install
(8)
(9)wget http://github.com/downloads/rvoicilas/inotify-tools/inotify-tools-3.14.tar.gz
tar zxvf inotify-tools-3.14.tar.gz
6,配置自动同步脚本
vim rsync.sh
#!/bin/sh
/usr/local/inotify/bin/inotifywait -mrq --timefmt '%d/%m/%y %H:%M' --format '%T %w %f %e' -e modify,delete,create,attrib /tmp/test/ \
| while read file
do
rsync -avzuP --delete /tmp/test/ root@192.168.192.136:/tmp/test/
echo "${file}" >>/var/log/rsyncd.log 2>&1
done
exit 0
```