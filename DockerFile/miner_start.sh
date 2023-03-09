#!/bin/bash
MINIP=`ip a | grep inet | grep -v inet6 | grep -v 127 | sed 's/^[ \t]*//g' | cut -d ' ' -f2 | awk -F '/' '{print $1}' | head -n 1`
if [ ! -d ~/.epikminer/datastore ]; then
/root/bin/epik-miner init && sleep 5m
sed  -i '/Libp2p/a\AnnounceAddresses = ["/ip4/${MINIP}/tcp/2458"]' ~/.epikminer/config.toml 
sed  -i '/Libp2p/a\ListenAddresses = ["/ip4/0.0.0.0/tcp/2458", "/ip6/::/tcp/2458"]' ~/.epikminer/config.toml 
/root/bin/epik-miner run 
else
/root/bin/epik-miner run 
fi