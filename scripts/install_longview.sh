#!/bin/bash

ips=(`make -s list-ips`)
# echo ${ips[@]}

for i in ${ips[@]}; do linode-cli longview create; done

apikeys=(`linode-cli longview list --text --no-header --format api_key`)
# echo ${tokens[@]}

c=0
for t in ${apikeys[@]}; do
	echo
        echo >&2 "SETUP ${ips[$c]}"
	echo
	ssh -l root -i ./sshkey ${ips[$c]} \
		-o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes \
		"echo ${apikeys[$c]} > /etc/linode/longview.key ; systemctl start longview; systemctl enable longview"
	c=$(( $c + 1 ))
done
