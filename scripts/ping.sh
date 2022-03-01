#!/bin/bash

timeout=5

declare -A avg
for i in `make -s list-ips`; do
    echo "Probing ping latency for ${i}..."
    avg["$i"]=`ping -c ${timeout} ${i} | tail -1| awk '{print $4}' | cut -d '/' -f 2`
done

tmp=`mktemp`
linode-cli --text --no-header --format ipv4,label,status linodes list > $tmp
while read i; do
    ip=`echo $i | awk '{print $1}'`
    ping=${avg["$ip"]}
    echo -e "$i\tping $ping"
done < ${tmp}
