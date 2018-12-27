#!/bin/bash

iptables=$1

${iptables}-save > /var/lib/${iptables}/data.conf
