# The Radiant Blockchain Developers
# The purpose of this image is to be able to host ElectrumX and radiantd (RXD) together.
# Build with: `docker build -t electrumxAndRadiantNode .`

FROM ubuntu:20.04

LABEL maintainer="code@radiant4people.com"
LABEL version="1.0.0"
LABEL description="Docker image for electrumx and radiantd node"
ARG DEBIAN_FRONTEND=nointeractive

ENV DAEMON_URL=http://${RPC_USER:-RadiantDockerUser}:${RPC_PASS:-RadiantDockerPassword}@localhost:7332/
ENV COIN=Radiant
ENV REQUEST_TIMEOUT=60
ENV DB_DIRECTORY=/root/electrumdb
ENV DB_ENGINE=leveldb
ENV SERVICES=tcp://0.0.0.0:50010,SSL://0.0.0.0:50012
ENV SSL_CERTFILE=/root/electrumdb/server.crt
ENV SSL_KEYFILE=/root/electrumdb/server.key
ENV HOST=""
ENV ALLOW_ROOT=true
ENV CACHE_MB=10000
ENV MAX_SESSIONS=10000
ENV MAX_SEND=10000000
ENV MAX_RECV=10000000

RUN apt update
RUN apt-get install -y curl
RUN curl -sL https://deb.nodesource.com/setup_18.x | bash -
RUN apt-get install -y nodejs

ENV PACKAGES="\
  build-essential \
  libcurl4-openssl-dev \
  software-properties-common \
  ubuntu-drivers-common \
  pkg-config \
  libtool \
  openssh-server \
  git \
  clinfo \
  autoconf \
  automake \
  libjansson-dev \
  libevent-dev \
  uthash-dev \
  nodejs \
  vim \
  libboost-chrono-dev \
  libboost-filesystem-dev \
  libboost-test-dev \
  libboost-thread-dev \
  libevent-dev \
  libminiupnpc-dev \
  libssl-dev \
  libzmq3-dev \ 
  help2man \
  ninja-build \
  python3 \
  python3-pip \
  libdb++-dev \
  wget \
  cmake \
  ocl-icd-* \
  opencl-headers \
  ocl-icd-opencl-dev\
"
RUN apt update && apt install --no-install-recommends -y $PACKAGES  && \
    rm -rf /var/lib/apt/lists/* && \
    apt clean

####################################################### INSTALL RADIANT-NODE
WORKDIR /root
RUN git clone --depth 1 --branch v1.2.0 https://github.com/radiantblockchain/radiant-node.git
RUN mkdir /root/radiant-node/build
WORKDIR /root/radiant-node/build
# Compile with wallet
# RUN cmake -GNinja .. -DBUILD_RADIANT_QT=OFF
# Compile without wallet (default)
RUN cmake -GNinja .. -DBUILD_RADIANT_WALLET=OFF -DBUILD_RADIANT_QT=OFF
RUN ninja
RUN ninja install
# Remove radiant-node folder, not need more
RUN rm /root/radiant-node -R
WORKDIR /root

COPY run.sh /run.sh
RUN chmod 755 /run.sh

EXPOSE 7333 50010 50012
VOLUME /root

ENTRYPOINT ["/bin/sh", "-c" , "run.sh"]
