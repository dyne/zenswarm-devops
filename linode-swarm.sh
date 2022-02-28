#!/bin/bash

info() { echo >&2 "$1"; }

# env defined by called makefile:
group=zenswarm
# nodetype=g6-nanode-1
# rootpass=`openssl rand -base64 32`
# sshkey := ${HOME}/sshkey-${group}

sshkey=`pwd`/sshkey
if ! [ -r ${sshkey} ]; then ssh-keygen -t ed25519 -f ${sshkey} -q -N ''; fi
#curl -sL https://api.linode.com/v4/regions | jq . | awk '/id.:/ {print $2}' | xargs

# regions=(ap-west ca-central ap-southeast us-central us-west us-southeast us-east eu-west ap-south eu-central ap-northeast)
# only 6
regions=(ca-central us-west us-east eu-central ap-west ap-southeast)

linode-cmd() {
    linode-up-dry
    linode-cli linodes ${1} --root_pass ${rootpass} --type ${nodetype} --group zenswarm --image ${image} --label zenswarm-${reg} --region ${reg} --authorized_keys "$(cat ${sshkey}.pub)"
}
linode-up-dry() {
    info "linode-cli linodes ${1} --root_pass ${rootpass} --type ${nodetype} --group zenswarm --image ${image} --label zenswarm-${reg} --region ${reg} --authorized_keys \"`cat ${sshkey}.pub`\""
}

# linode-cli linodes list format
#   2    4       6        8      10      12        14
# │ id │ label │ region │ type │ image │ status  │ ipv4 │
linode-list() {
    linodes=(`linode-cli --format id,label,region,status,ipv4 --text --delimiter , --no-headers  linodes list`)
    pos=0
    case $1 in
	id|ids) pos=1 ;;
	label|name) pos=2 ;;
	reg|regions) pos=3 ;;
	status) pos=4 ;;
	ip|ips) pos=5 ;;
    esac
    for i in ${linodes[@]}; do
	echo $i | cut -d, -f${pos}
    done
}

pause() {
    echo -n >&2 "."
    sleep $1
}

linode-wait-running() {
    running=0
    while [ $running = 0 ]; do
	linode-cli linodes list | grep provisioning
	running=$?
	sleep 1
    done
    pause 1
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
}

cmd="$1"
case $cmd in
    one-up)
	reg=${2:-eu-central}
	image=${3:-debian11}
	linode-cmd create
	;;
    ip)
	reg=${2:-eu-central}
	linode-list ip
	;;
    id)
	reg=${2:-eu-central}
	linode-list id
	;;

    wait-running)
	linode-wait-running
	;;

    announce)
	info "Announce all nodes"
	ids=(`linode-cli linodes list | awk "/${group}/"' {print $14}'`)
	for i in ${ids[@]}; do
	    curl -X 'POST' "http://${i}:3300/api/consensusroom-announce.chain"
	done
	;;

    reboot)
	info "Reboot all nodes"
	ids=(`linode-cli linodes list | awk "/${group}/"' {print $14}'`)
	for i in ${ids[@]}; do
	    info "reboot ${i}"
	    ssh -i ${sshkey} root@${i} -c 'init 6'
	done
	;;

    all-up)
	for reg in ${regions[@]}; do
	    linode-cmd create
	done
	;;

    all-down)
	ids=(`linode-cli linodes list | awk ''"/${group}/"' {print $2","$4","$14}'`)
	for i in ${ids[@]}; do
	    f=(${i//,/ })
	    info "delete ${f[1]} (${f[2]})"
	    linode-cli linodes delete ${f[0]};
	done
	;;
    list-ips)
	ips=(`linode-cli linodes list | awk ''"/${group}/"' {print $14}'`)
	if [ ${#ips} = 0 ]; then
	    info "Zero nodes found."
	    exit 1
	fi
	for i in ${ips[@]}; do
	    echo "$i"
	done
	;;

    install|install.yaml)
	shift 1
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook install.yaml \
	--private-key ${sshkey} --inventory hosts.toml $*
	;;

    deploy|deploy.yaml)
	shift 1
	ANSIBLE_HOST_KEY_CHECKING=False \
	ansible-playbook deploy.yaml \
	--private-key ${sshkey} --inventory hosts.toml $*
	;;
    'source') ;;
    *)
	info "usage: $0 [ one-up/down | all-up/down | inventory ]"
	;;
esac
