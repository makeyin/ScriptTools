wallet=`curl -s -X POST \
     -H "Content-Type: application/json" \
     --data '{
       "jsonrpc":"2.0",
       "method":"Filecoin.WalletBalance",
       "params":[
          "f3shhfnkmar43s2lik7vvps6nod5som6nln5zoxehshgbhz6kcy35dzclfq4rgjsugy7cpvkmff5x4bgquexaq"
       ],
       "id":7878
     }' \
	     http://172.20.4.151:1234/rpc/v0 | jq -r '.result | tonumber /1000000000000000000' |awk -F '[F.]' '{print $1}'`
if [ "$wallet" -gt  "1" ];then
curl 'https://oapi.dingtalk.com/robot/send?access_token=90613a748f715e8aaa84d02e58542fff2ab2d1a204d2074c8c2190d21ff4bf47' \
   -H 'Content-Type: application/json' \
   -d '{"msgtype": "text",
        "text": {
             "content": "：当前余额为'${wallet}'"
        }
      }'
fi








####################################################python3写法#####################################################################
import requests
import json

res = requests.get(curl -s -X POST \
     -H "Content-Type: application/json" \
     --data '{
       "jsonrpc":"2.0",
       "method":"Filecoin.WalletBalance",
       "params":[
          "f3shhfnkmar43s2lik7vvps6nod5som6nln5zoxehshgbhz6kcy35dzclfq4rgjsugy7cpvkmff5x4bgquexaq"
       ],
       "id":7878
     }' \
             http://172.20.4.151:1234/rpc/v0 | jq -r '.result | tonumber /1000000000000000000' |awk -F '[F.]' '{print $1}')


url='https://oapi.dingtalk.com/robot/send?access_token=90613a748f715e8aaa84d02e58542fff2ab2d1a204d2074c8c2190d21ff4bf47'
program={
        "msgtype": "text",
        "text": {"content": wallet},
        }
headers={'Content-Type': 'application/json'}
f=requests.post(url,data=json.dumps(program),headers=headers)
