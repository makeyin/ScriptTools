#build
#docker build -t subspace:1.1 .
###启动前 先创建文件夹  mkdir -p /subspace/

########-----------------------start node-----------------------########
#docker run --name subspace -v /data/subspace:/data/subspace -v /data/subspace/data:/root/.local -e "SUBSPACE_NODENAME=nash123" -e "SUBSPACE_WALLET=st8uDzXV8RtUZ1wTMjJzQm1UVfCt6G6gdhcyXTR4prT2XSJPm" --restart always -d subspace:1.6


FROM ubuntu:20.04
WORKDIR /subspace
COPY node  farmer start_farmer.sh  entrypoint.sh /subspace/
RUN ["apt-get", "update"]
RUN ["apt-get", "install", "ocl-icd-opencl-dev", "libgomp1", "libssl-dev","-y"]
ENTRYPOINT ["/subspace/entrypoint.sh"]