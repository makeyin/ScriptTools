#!/usr/bin/expect
spawn ./ppd config -w -p
expect "password"
send "Night123\n"
expect "again"
send "Night123\n"
expect "nickname"
send "nash\n"
expect "password"
send "Night123\n"
expect "again"
send "Night123\n"
expect "input"
send "prize wage jelly session prison crash various shed stomach estate asset distance skull cry dinner arena olive nation mechanic hunt robot helmet adjust stereo\n"
expect "input"
send "\n"
expect "save"
send "Y\n"
expect off

