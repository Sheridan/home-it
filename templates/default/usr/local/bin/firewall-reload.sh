#!/bin/bash

ip_ver=$1

iptables="iptables"
if [ "$ip_ver" = "6" ]
then
    iptables="ip6tables"
fi

if [ -e /etc/iptables/iptables.${ip_ver}.conf ]
then
    ${iptables}-restore < /etc/iptables/iptables.${ip_ver}.conf || exit 1
    /usr/local/bin/firewall-save.sh ${ip_ver} || exit 1
fi
