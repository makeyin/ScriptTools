#!/bin/bash

cd /data/forta

if [ -z "$FORTA_PASS" ]
then
  export FORTA_PASS=qsobadforta
fi

if [ -z "$FORTA_CHAIN" ]
then
  export FORTA_CHAIN="eth"
fi

if [ ! -d "/data/forta/.keys" ]
then
  forta init --passphrase $FORTA_PASS --dir /data/forta > /data/forta/init.log 2>&1

if [ "$FORTA_CHAIN" == "polygon" ]
then

  echo "
chainId: 137

scan:
  jsonRpc:
  url: https://polygon-rpc.com/

trace:
  enabled: false
" > /data/forta/config.yml

else

  echo "
chainId: 1

scan:
  jsonRpc:
    url: https://cloudflare-eth.com/

trace:
  jsonRpc:
    url: https://cloudflare-eth.com/
" > /data/forta/config.yml

fi
fi

if [ -z "$FORTA_SLEEP" ]
then
  /bin/bash
else
  sleep 100000
fi