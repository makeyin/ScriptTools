wget https://github.com/ethersphere/exportSwarmKey/releases/download/v0.1.0/export-swarm-key-linux-amd64
chmod +x export-swarm-key-linux-amd64
read -p "请输入当前服务器节点数量：" BEE_NUM
while ! [[ "$BEE_NUM" =~ ^[0-9]+$ ]];do
	echo "请输入数字"
	read -p "请确认当前服务器运行节点数量 [0或其它数字]：" BEE_NUM
	if [ "$BEE_NUM" -lt 0 ];then exit;fi
done
for BEE_DIR in `seq ${BEE_NUM}`
do
	printf "/var/lib/bee/node${BEE_DIR} 私钥：\n"
	/root/export-swarm-key-linux-amd64 /var/lib/bee/node${BEE_DIR}/keys yi23dy | grep swarm.key | awk -F, '{print $2}' | awk -F\" '{print $4}' 
done


