#build
#docker build -t subspace:1.1 .
###启动前 先创建文件夹  mkdir -p /data/subspace/data

########-----------------------start node-----------------------########
#docker run --name subnode -v /data/subspace:/data/subspace -v /data/subspace/data:/root/.local \
# -e "SUBSPACE_NODENAME=nash"  -p "30333:30333" -p "9944:9944" --restart always -d subspace:1.1

#########-----------------------start farmer  -----------------------########
#docker run --name subfarmer1 -v /subdata1:/subspace/farmerbase  \
# -e "SUBSPACE_WALLET=st8uDzXV8RtUZ1wTMjJzQm1UVfCt6G6gdhcyXTR4prT2XSJPm" -e "SUBSPACE_SIZE=30T"  \
#-e "SUBSPACE_FPORT=9923" -p "9923:9923" --restart always -d subspace:1.1


FROM ubuntu:20.04
RUN mkdir  -p /subspace/farmerbase
WORKDIR /forta
ADD forta .  
ADD entrypoint.sh .
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "ocl-icd-opencl-dev", "libgomp1", "docker.io", "libssl-dev","-y"]
ENTRYPOINT ["/bin/bash", "-c", "./entrypoint.sh"]