#!/bin/bash

iptables=$1

/usr/local/bin/firewall-save.sh $iptables
# /usr/local/bin/firewall-load.sh $iptables
