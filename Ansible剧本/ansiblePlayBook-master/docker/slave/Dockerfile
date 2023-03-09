FROM lotus:0.0.1

RUN set -x \
    && apt install apt-utils  mesa-opencl-icd ocl-icd-opencl-dev vim wget -y \
    && apt-get clean \
    && mkdir -p /root/bin
#RUN groupadd filecoin
#RUN useradd -d /home/devnet  -g filecoin  -m -s /bin/bash devnet
#RUN echo "devnet:devnet" | chpasswd
#ADD lotus-slave-miner   /root/bin
ADD lotus-poster /root/bin
#ADD test.sh /root/bin
#USER devnet

#RUN /bin/bash -c '/root/bin/lotus-slave-miner init'
#RUN /bin/bash -c '/root/bin/lotus-poster init'

VOLUME ["/root"]

ENTRYPOINT  ["/root/bin/lotus-poster", "run"]