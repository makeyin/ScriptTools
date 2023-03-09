#/bin/bash
##### docker-nvidia 安装 ##############



####### 创建统一存储卷 #############
volume=testnet_1475
docker volume create $volume
echo 卷目录: "/var/lib/docker/volumes/$volume"
##### 快捷访问软链 #####
ln -snf /var/lib/docker/volumes/$volume/_data/.lotusslave  /tank1/.lotusslave
ln -snf /var/lib/docker/volumes/$volume/_data/.lotusposter  /tank1/.lotusposter
ln -snf /var/lib/docker/volumes/$volume/_data/bin  /tank1/bin
#### 打包镜像 ####
docker build  -t lotus_slave:0.1.2 --no-cache slave/.
docker build  -t lotus_poster:0.1.2 --no-cache poster/.
#### 创建容器 ####
docker rm -f lotus-slave
docker rm -f lotus-poster
docker run -dit --name lotus-slave  -p 3456:3456 -p 8000:8000   --net=host  -v /var/tmp/filecoin-proof-parameters:/var/tmp/filecoin-proof-parameters -v $volume:/root  lotus_slave:0.1.2
docker run -dit --name lotus-poster  -p 9000:9000 -p 4567:4567  --net=host  -v /var/tmp/filecoin-proof-parameters:/var/tmp/filecoin-proof-parameters -v $volume:/root  lotus_poster:0.1.2

echo .lotusslave目录: "/tank1/.lotusslave"
echo bin目录: "/tank1/bin"