# The Radiant Blockchain Developers
# The purpose of this image is to be able to host ElectrumX and radiantd (RXD) together.
# Build with: `docker build -t electrumxAndRadiantNode .`

FROM ubuntu:20.04

LABEL maintainer="code@radiant4people.com"
LABEL version="1.0.0"
LABEL description="Docker image for electrumx and radiantd node"

ARG DEBIAN_FRONTEND=nointeractive
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

RUN mkdir "/root/.radiant/"
RUN touch "/root/.radiant/radiant.conf"

RUN echo '\
rpcuser=RadiantDockerUser\n\
rpcpassword=RadiantDockerPassword\n\
\n\
listen=1\n\
daemon=1\n\
server=1\n\
rest=1\n\
daemon=1\n\
rpcworkqueue=1024\n\
rpcthreads=64\n\
rpcallowip=0.0.0.0/0\
' >/root/.radiant/radiant.conf 

####################################################### INSTALL ELECTRUMX WITH SSL

# Create directory for DB
RUN mkdir /root/electrumdb

WORKDIR /root

# ORIGINAL SOURCE
RUN git clone --depth 1 --branch master https://github.com/radiantblockchain/electrumx.git

WORKDIR /root/electrumx

RUN python3 -m pip install -r requirements.txt

ENV DAEMON_URL=http://RadiantDockerUser:RadiantDockerPassword@localhost:7332/
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

# Create SSL
WORKDIR /root/electrumdb
RUN openssl genrsa -out server.key 2048
RUN openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=radiant4people.com"
RUN openssl x509 -req -days 1825 -in server.csr -signkey server.key -out server.crt

EXPOSE 7333 50010 50012

ENTRYPOINT ["/bin/sh", "-c" , "radiantd && python3 /root/electrumx/electrumx_server"]
