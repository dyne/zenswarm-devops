R ?= $(shell pwd)
REGION ?= eu-central
# IMAGE ?= linode/debian11
rootpass := $(shell openssl rand -base64 32)
nodetype := g6-nanode-1
sshkey := ${R}/sshkey
# regions=(ap-west ca-central ap-southeast us-central us-west us-southeast us-east eu-west ap-south eu-central ap-northeast)
regions := ca-central us-west us-east eu-central ap-west ap-southeast
# only 6
export

##@ General
help:
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile

ANSIPLAY = ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --inventory hosts.toml --ssh-common-args '-o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes' --private-key ${sshkey} "roles/$(1)"

LINCREATE = xargs -I {} linode-cli linodes create --root_pass ${rootpass} --type ${nodetype} --group zenswarm --image $(1) --label zenswarm-"{}" --region "{}" --authorized_keys "$(shell cat ${sshkey}.pub)"
LINVIEW = xargs -I {} linode-cli linodes view "{}"

play:
	$(if ${BOOK},,$(error Specify ansible playbook in BOOK env))
	$(call ANSIPLAY,${BOOK})

steps:
	@cat $(subst -steps,,${PLAYBOOK}) | grep '\- name'

regions: ## list available regions
	@linode-cli regions list

ssh-keygen: ## generate a dedicated ssh keypair here
	$(if $(wildcard ${sshkey}),,\
		$(info Generating ssh keypair) \
		ssh-keygen -t ed25519 -f ${sshkey} -q -N '')

ssh-cleanup: ## clean all fingerprints from known hosts
	@make -s list-ips | xargs -I {} \
		ssh-keygen -q -f "${HOME}/.ssh/known_hosts" -R "{}"

##@ Node lifecycle
list: ## list running nodes (list-ips for IPv4 only)
	@linode-cli linodes list

list-ips:
	@linode-cli --text --no-header --format ipv4 linodes list

inventory:
	@echo "[zenswarm]" >  hosts.toml
	@make -s list-ips >> hosts.toml
	$(info Inventory updated in hosts.toml)

all-up: IMAGE ?= $(shell linode-cli --format id,label --text --no-headers images list | awk '/zenswarm/ {print $$1}')
all-up: ssh-keygen
	$(if ${IMAGE}, \
		$(info Zenswarm image found: ${IMAGE}), \
		$(error Zenswarm image not found, use image-build first))
	$(info Creating active nodes in all regions: ${regions})
	@for i in ${regions}; do echo $$i; done | $(call LINCREATE,${IMAGE})
	@make -s ssh-cleanup
	@./scripts/wait-running.sh

teardown: inventory ## destroy all active nodes
	$(info Destroying existing nodes in all regions)
	@linode-cli --text --no-header --format id linodes list \
	| xargs -I {} linode-cli linodes delete "{}"

one-up: IMAGE ?= $(shell linode-cli --format id,label --text --no-headers images list | awk '/zenswarm/ {print $$1}')
one-up: ssh-keygen ## create 1 active node in REGION (eu-central is default)
	$(if ${IMAGE}, \
		$(info Zenswarm image found: ${IMAGE}), \
		$(error Zenswarm image not found, use image-build first))	
	$(info Creating one node in region ${REGION})
	@echo ${REGION} | $(call LINCREATE,${IMAGE})
	@make -s ssh-cleanup
	@./scripts/wait-running.sh

longview: ## install longview monitoring on nodes (resets current)
	$(info Install longview on nodes)
	$(call ANSIPLAY,longview.yaml)
	$(info Deleting all existing longview clients)
	@linode-cli longview list --text --no-header --format id | xargs -I {} linode-cli longview delete "{}"
	$(info Setting up longview on all nodes)
	@bash ./scripts/install_longview.sh

##@ Image operations

image-init: ## setup golden image development on linode
	packer init packer/config.pkr.hcl

image-build: linode-token := $(shell awk '/token/ {print $$3}' ${HOME}/.config/linode-cli)
image-build: tmp := $(shell mktemp)
image-build: ## build the zenswarm golden image on linode
	@sed "s/linode_token=\"\"/linode_token=\"${linode-token}\"/g" packer/linode.pkr.hcl > ${tmp}.pkr.hcl
	-cd packer && packer build ${tmp}.pkr.hcl
	rm -f ${tmp} ${tmp}.pkr.hcl

image-delete: IMAGE ?= $(shell linode-cli --format id,label --text --no-headers images list | awk '/zenswarm/ {print $$1}')
image-delete: ## delete the zenswarm golden image on linode
	linode-cli images delete ${IMAGE}

##@ App management

deploy: inventory ## deploy the zencode contracts on all available nodes
	$(if $(wildcard roles/install.zip), \
		$(info Installing all nodes) \
		$(call ANSIPLAY,deploy.yaml) \
	, $(error Zencode not found, install.zip is missing))

announce: inventory ## announce all nodes to the tracker endpoint
	make -s list-ips \
	| xargs -I {} curl -X 'POST' \
	              "http://{}:3300/api/consensusroom-announce.chain"

ssh: login ?= root
ssh: ip ?= $(shell linode-cli --text --no-header --format region,ipv4 linodes list | awk '/${REGION}/{print $$2}')
ssh: ## log into a node in REGION via ssh (eu-central is default)
	$(info Logging into node via ssh on region ${REGION})
	ssh -l ${login} -i ${sshkey} \
	  -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes ${ip}

ssh-exec: login ?= root
ssh-exec: ip ?= $(shell linode-cli --text --no-header --format region,ipv4 linodes list | awk '/${REGION}/{print $$2}')
ssh-exec: ## execute CMD on all nodes via ssh
	$(if ${CMD},\
	$(info Executing command on all nodes via ssh: ${CMD}),\
	$(error Command not defined, set env var CMD))
	@make -s list-ips | xargs -I {} ssh -l ${login} -i ${sshkey} \
	  -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes "{}" ${CMD}

uptime: inventory ## show uptime of all running nodes
	$(info Showing uptime for all running nodes)
	$(call ANSIPLAY,uptime.yaml)

ping: ## show ping of all running nodes
	make -s list-ips | xargs -I {} ping -q -c 5 -n "{}"

reboot: inventory ## reboot all running nodes
	$(call ANSIPLAY,reboot.yaml)

