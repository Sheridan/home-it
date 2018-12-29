#!/bin/bash

ip_ver=$1

iptables="iptables"
if [ "$ip_ver" = "6" ]
then
    iptables="ip6tables"
fi

if [ -e /var/lib/iptables/data.${ip_ver}.conf ]
then
    ${iptables}-restore < /var/lib/iptables/data.${ip_ver}.conf || exit 1
else
    ${iptables}-restore < /etc/iptables/iptables.${ip_ver}.conf || exit 1
fi
