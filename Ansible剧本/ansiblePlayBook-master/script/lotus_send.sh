#!/bin/sh
if which tput >/dev/null 2>&1; then
      ncolors=$(tput colors)
fi
if [ -t 1 ] && [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
    RED="$(tput setaf 1)"
    GREEN="$(tput setaf 2)"
    YELLOW="$(tput setaf 3)"
    BLUE="$(tput setaf 4)"
    BOLD="$(tput bold)"
    NORMAL="$(tput sgr0)"
else
    RED=""
    GREEN=""
    YELLOW=""
    BLUE=""
    BOLD=""
    NORMAL=""
fi
defaultWallet=`~/bin/lotus wallet default`
#read -p "有钱的钱包地址" send
read -p "${RED}没钱的钱包地址:"${BLUE} receive
noReceive=`~/bin/lotus wallet balance $receive`
echo ${RED}这个钱包现在余额:${BLUE}$noReceive
read -p "${RED}转多少钱:"${BLUE} money
~/bin/lotus send --source $defaultWallet  $receive $money
sleep 2m
echo `~/bin/lotus wallet balance $receive`