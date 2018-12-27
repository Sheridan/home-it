#!/bin/bash

iptables=$1

if [-e /var/lib/${iptables}/data.conf]
then
    ${iptables}-restore < /var/lib/${iptables}/data.conf
fi
