#!/bin/bash

dolabels=0
tmp_path="/tmp"
smartctl_exec="/usr/sbin/smartctl"
items_count=1
items=""

function inarray()
{
    val=$1
    index=1
    element_count=${#items[@]}
    while [ "$index" -lt "$element_count" ]
    do
        if echo "${items[$index]}" | grep -q "${val}"
        then
            return 1
        fi
        ((index = index + 1))
    done
    return 0
}

for dev in $(${smartctl_exec} --scan | awk '{print $1}')
do
    device=$(basename $dev)
    tmp_file="${tmp_path}/smartctl.${device}"
    ${smartctl_exec} --attributes --info --format=brief $dev > "${tmp_file}"
    dev_family=`cat $tmp_file | grep "Model Family" | sed -e 's@.*:[[:space:]]*\(.*\)@\1@ig'`
    dev_model=`cat $tmp_file | grep "Device Model" | sed -e 's@.*:[[:space:]]*\(.*\)@\1@ig'`
    dev_sn=`cat $tmp_file | grep "Serial Number" | sed -e 's@.*:[[:space:]]*\(.*\)@\1@ig'`
    dev_firmware=`cat $tmp_file | grep "Firmware Version" | sed -e 's@.*:[[:space:]]*\(.*\)@\1@ig'`
    user_capacity=`cat $tmp_file | grep "User Capacity" | sed -e 's@.*:[[:space:]]*\(.*\)bytes.*@\1@ig' | sed -e 's@,@@g' | tr -d " " | xargs`

    sata_version=`cat $tmp_file | grep "^SATA Version is:" | sed -e 's@.*:[[:space:]]*SATA[[:space:]]*\(.*\),.*@\1@ig' | awk -v def="Unknown" '{print} END {if(NR==0) {print def}}' `
    ata_version=`cat $tmp_file | grep "^ATA Version is:" | sed -e 's@.*:[[:space:]]*\(.*\)@\1@ig' | sed -e "s@ (Minor.*)@@ig" | awk -v def="Unknown" '{print} END {if(NR==0) {print def}}' `

    echo "smartctl_device_meta{ata_version=\"${ata_version}\",sata_version=\"${sata_version}\",family=\"${dev_family}\",model=\"${dev_model}\",sn=\"${dev_sn}\",firmware=\"${dev_firmware}\",device=\"${dev}\"} 1";
    echo "smartctl_user_capacity{device=\"${dev}\"} ${user_capacity}"
    echo -n "smartctl_smart_avialable{device=\"${dev}\"} "; cat "${tmp_file}" | grep "SMART support is: Available" -c
    echo -n "smartctl_smart_enabled{device=\"${dev}\"} "; cat "${tmp_file}" | grep "SMART support is: Enabled" -c
    if cat "${tmp_file}" | grep "SATA Version is:" | grep -q "current"
    then
        echo -n "smartctl_sata_throughput{device=\"${dev}\"} "; cat "${tmp_file}" | grep "SATA Version is:" | sed -e 's@.*current:.+\?\([\.0-9]*\).*@\1@i'
    fi
    if cat "${tmp_file}" | grep "Rotation Rate" | grep -vq "Solid"
    then
        echo -n "smartctl_rotation_rate{device=\"${dev}\"} "; cat "${tmp_file}" | grep "Rotation Rate" | sed -e 's@.*:[[:space:]]*\([0-9]*\).*@\1@i'
    fi
    items_count=1
    items=""
    cat "${tmp_file}" | egrep "([P-][O-][S-][R-][C-][K-])" | while read sval
    do
        screenlabel=`echo $sval | awk -v ORS="" '{ print $2 }'`
        screenlabel=${screenlabel//_/ }
        screenlabel=${screenlabel//-/ }
        id=`echo $sval | awk -v ORS="" '{ print $1 }'`
        flags=`echo $sval | awk -v ORS="" '{ print $3 }'`
        fail=`echo $sval | awk -v ORS="" '{ print $7 }'`
        label=`echo $sval | awk -v ORS="" '{ gsub(/-/, "_"); print tolower($2) }'`
        echo -n "smartctl_attribute{id=\"${id}\",name=\"${screenlabel}\",type=\"value\",device=\"${dev}\"} "; echo $sval | awk '{print $4}'
        echo -n "smartctl_attribute{id=\"${id}\",name=\"${screenlabel}\",type=\"threshold\",device=\"${dev}\"} "; echo $sval | awk '{print $5}'
        echo -n "smartctl_attribute{id=\"${id}\",name=\"${screenlabel}\",type=\"worst\",device=\"${dev}\"} "; echo $sval | awk '{print $6}'
        echo -n "smartctl_attribute{id=\"${id}\",name=\"${screenlabel}\",type=\"raw\",device=\"${dev}\"} "; echo $sval | awk '{print $8}' | sed -e 's@\([0-9]*\).*@\1@ig'
        echo "smartctl_attribute_meta{id=\"${id}\",name=\"${screenlabel}\",device=\"${dev}\",flags=\"${flags}\",fail=\"${fail}\"} 1";
        items[$items_count]=$label
        ((items_count=items_count+1))
    done
    dolabels=0
done
