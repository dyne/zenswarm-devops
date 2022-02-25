R ?= $(shell pwd)
REGION ?= eu-central
rootpass := $(shell openssl rand -base64 32)
nodetype := g6-nanode-1
group := consensusroom
sshkey := ${R}/sshkey-${group}
export

##@ General
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile

ANSIPLAY = ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --inventory hosts.toml --ssh-common-args '-o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes' --private-key ${sshkey} $(1)

ansiplay:
	$(call ANSIPLAY, ${PLAYBOOK})

ansishow:
	@cat $(subst -steps,,${PLAYBOOK}) | grep '\- name'

regions: ## list available regions
	@curl -sL https://api.linode.com/v4/regions \
	| jq . | awk '/id.:/ {print $$2} /country.:/ {print $$2"\n"}'

ssh-keygen: ## generate a dedicated ssh keypair here
	$(if $(wildcard ${sshkey}),,\
		$(info Generating ssh keypair) \
		ssh-keygen -t ed25519 -f ${sshkey} -q -N '')

##@ Node lifecycle
list: ## list running nodes (list-ips for IPv4 only)
	@linode-cli linodes list

list-ips:
	@./linode-swarm.sh list-ips

inventory: ## update the ansible inventory of active nodes
	@echo "[${group}]" >  hosts.toml
	@make -s list-ips >> hosts.toml
	$(info Inventory updated in hosts.toml)

all-up: ## create 11 active nodes, one for each linode region
	$(info Creating active nodes in all available regions)
	@./linode-swarm.sh all-up

all-down: inventory ## destroy all active nodes
	$(info Destroying existing nodes in all regions)
	@./linode-swarm.sh all-down

one-up: ## create one active node in REGION (eu-west is default)
	$(info Creating one node in region ${REGION})
	@./linode-swarm.sh $(shell ./linode-swarm.sh id) ${REGION}

one-down: ## destroy one active node in REGION (eu-west is default)
	$(info Destroying one node in region ${REGION})
	@linode-cli linodes delete $(shell linode-swarm.sh id) ${REGION} 


##@ Node operations

install: inventory ssh-keygen ## install the zencode api server on all available nodes
	$(info Installing all nodes)
	$(call ANSIPLAY, install.yaml)
	$(call ANSIPLAY, install-restroom.yaml)

install-restroom: inventory ssh-keygen
	$(call ANSIPLAY, install-restroom.yaml)

deploy: inventory ssh-keygen ## deploy the zencode contracts on all available nodes
	$(info Installing all nodes)
	$(call ANSIPLAY, deploy.yaml)

announce:
	make -s list-ips \
	| xargs -I {} curl -X 'POST' \
	              "http://{}:3300/api/consensusroom-announce.chain"

ssh: ssh-login ?= app
ssh: ssh-keygen ## log into a node in REGION via ssh (eu-west is default)
	$(info Logging into node via ssh on region ${REGION})
	ssh -l ${ssh-login} -i ${sshkey} \
	  -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes \
	  $(shell ./linode-swarm.sh ip ${REGION})

uptime: inventory ## show uptime of all running nodes
	$(info Showing uptime for all running nodes)
	$(call ANSIPLAY, uptime.yaml)

reboot: inventory
	$(call ANSIPLAY, reboot.yaml)

restart: inventory
	$(info ANSIPLAY, restart.yaml)
