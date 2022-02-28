#!/bin/bash

running=0
while [ $running = 0 ]; do
	linode-cli linodes list | grep provisioning
	running=$?
	sleep 5
done
sleep 1

ips=(`linode-list ip`)
info ${ips}
booting=1
for i in ${ips[@]}; do
	info "wait for $i"
	while ! [ $booting = 0 ]; do
	    ssh -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes \
		-o ConnectTimeout=1 -i ${sshkey} root@${i} uptime
	    booting=$?
	    sleep 5
	done
	booting=1
done
sleep 1

