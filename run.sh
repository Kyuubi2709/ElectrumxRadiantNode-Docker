#!/usr/bin/env bash

if [[ ! -f /root/.radiant/radiant.conf ]]; then
echo -e "Creating config file..."
mkdir /root/.radiant > /dev/null 2>&1
touch /root/.radiant/radiant.conf
cat <<- EOF > /root/.radiant/radiant.conf
rpcuser=${RPC_USER:-RadiantDockerUser}
rpcpassword=${RPC_PASS:-RadiantDockerPassword}
listen=1
daemon=1
server=1
rest=1
daemon=1
rpcworkqueue=1024
rpcthreads=64
rpcallowip=0.0.0.0/0
EOF
fi

cd /root
mkdir /root/electrumdb > /dev/null 2>&1
if [[ ! -d /root/electrumx ]]; then
  echo -e "Install electrumx..."
  git clone --depth 1 --branch master https://github.com/radiantblockchain/electrumx.git > /dev/null 2>&1
  cd /root/electrumx
  python3 -m pip install -r requirements.txt > /dev/null 2>&1
fi

if [[ ! -f /root/electrumdb/server.key ]]; then
  cd /root/electrumdb
  echo -e "Generate SSL certyficate...."
  openssl genrsa -out server.key 2048 > /dev/null 2>&1
  openssl req -new -key server.key -out server.csr -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=radiant4people.com" > /dev/null 2>&1
  openssl x509 -req -days 1825 -in server.csr -signkey server.key -out server.crt > /dev/null 2>&1
fi

bash -c "radiantd && python3 /root/electrumx/electrumx_server"
