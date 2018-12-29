#!/bin/bash

ip_ver=$1

iptables="iptables"
if [ "$ip_ver" = "6" ]
then
    iptables="ip6tables"
fi

${iptables}-save > /var/lib/iptables/data.${ip_ver}.conf || exit 1
