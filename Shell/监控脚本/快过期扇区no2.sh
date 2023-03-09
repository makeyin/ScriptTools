########power

userjia=`ps -ef |grep '/bin/lotus-pow[er]' |awk -F '[ /]+' '{print $8}'|sort -r |head -n1`
user=`ps -ef |grep /bin/lotus-pow[er] |awk -F '[ /]+' '{print $9}' |head -n1`
token=`cat /$userjia/$user/.lotusminer/config.toml |grep  'FullNodeToken' |grep -v '#' |awk -F '"' '{print $2}'`
export FULLNODE_API_INFO=$token
/$userjia/$user/bin/view_lotus.sh check 16 |grep -A 500 '快过期的扇区状态信息:' | grep -v compute > sectors1 && sed -i '1d' sectors1 && cat sectors1|awk -F "[()]" '{print $2,$3,$1}' > sectors3
########################################




---
- hosts: all
  gather_facts: no
  vars:
  - amazon_linux_ami: "ami-fb8e9292"
  - user_data_file: "/root/sectors"
  tasks:
    - name: 强制清理环境
      become: yes
      ignore_errors: True
      shell: cat {{ user_data_file }}
      register: user_data_action

    - name: 删除旧的bin文件
      shell: echo {{ user_data_file }}


















































#!/bin/bash
cat >/script/jkxx/sqgq.sh<<'EOF'
curl 'https://oapi.dingtalk.com/robot/send?access_token=90613a748f715e8aaa84d02e58542fff2ab2d1a204d2074c8c2190d21ff4bf47' \
   -H 'Content-Type: application/json' \
   -d '{"msgtype": "text",
        "text": {
             "content": "
各节点即将过期的扇区数：
EOF
runuser -l devnet -c 'bin/lotus state sectors-check --after-hours 0 '|sed 's#$#\\n#g' >>/script/jkxx/sqgq.sh
cat >>/script/jkxx/sqgq.sh<<'EOF'
        "
        },
        "at": {"isAtAll": true}
      }'
EOF