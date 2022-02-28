R ?= $(shell pwd)
REGION ?= eu-central
IMAGE ?= debian11
rootpass := $(shell openssl rand -base64 32)
nodetype := g6-nanode-1
sshkey := ${R}/sshkey
export

##@ General
help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' Makefile

ANSIPLAY = ANSIBLE_HOST_KEY_CHECKING=False ansible-playbook --inventory hosts.toml --ssh-common-args '-o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes' --private-key ${sshkey} $(1)

play:
	$(if ${BOOK},,$(error Specify ansible playbook in BOOK env))
	$(call ANSIPLAY, ${BOOK})

steps:
	@cat $(subst -steps,,${PLAYBOOK}) | grep '\- name'

regions: ## list available regions
	@curl -sL https://api.linode.com/v4/regions \
	| jq . | awk '/id.:/ {print $$2} /country.:/ {print $$2"\n"}'

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
	@./linode-swarm.sh list-ips

inventory: ## update the ansible inventory of active nodes
	@echo "[zenswarm]" >  hosts.toml
	@make -s list-ips >> hosts.toml
	$(info Inventory updated in hosts.toml)

all-up: ## create 11 active nodes, one for each linode region
	$(info Creating active nodes in all available regions)
	@./linode-swarm.sh all-up
	@make -s ssh-cleanup
	@./linode-swarm.sh wait-running

all-down: inventory ## destroy all active nodes
	$(info Destroying existing nodes in all regions)
	@./linode-swarm.sh all-down

one-up: ssh-keygen ## create 1 active node in REGION (eu-central is default)
	$(info Creating one node in region ${REGION})
	@./linode-swarm.sh one-up ${REGION} ${IMAGE}
	@make -s ssh-cleanup
	@./linode-swarm.sh wait-running

one-down: ## destroy one active node in REGION (eu-central is default)
	$(info Destroying one node in region ${REGION})
	@linode-cli linodes delete $(shell ./linode-swarm.sh id ${REGION})

##@ Image operations

image-setup: ## setup golden image development
	@make -s one-up
	linode-cli volumes create --label 

image-install: ## install the zenswarm golden image
	$(info Installing golden image)
	$(call ANSIPLAY, install-devuan-stage1.yaml)
	@make -s ssh-cleanup
	@./linode-swarm.sh wait-running
	$(call ANSIPLAY, install-devuan-stage2.yaml)
	@./linode-swarm.sh wait-running
	$(call ANSIPLAY, install-login.yaml)
	$(call ANSIPLAY, install.yaml)

image-save: ## save the zenswarm golden image

# $(call ANSIPLAY, install-restroom.yaml)

##@ Node operations

install: inventory ssh-keygen ## install the zencode api server on all available nodes
	$(info Installing all nodes
	$(call ANSIPLAY, install-devuan-stage1.yaml)
	@make -s ssh-cleanup
	@./linode-swarm.sh wait-running
	$(call ANSIPLAY, install-devuan-stage2.yaml)
	@./linode-swarm.sh wait-running
	$(call ANSIPLAY, install-login.yaml)
	$(call ANSIPLAY, install.yaml)
	$(call ANSIPLAY, install-restroom.yaml)
	$(if $(wildcard ./install.zip), \
		$(call ANSIPLAY, deploy.yaml), \
	$(info Skipped deploy, install.zip not found. Use: make deploy))

deploy: inventory ssh-keygen ## deploy the zencode contracts on all available nodes
	$(info Installing all nodes)
	$(call ANSIPLAY, deploy.yaml)

announce:
	make -s list-ips \
	| xargs -I {} curl -X 'POST' \
	              "http://{}:3300/api/consensusroom-announce.chain"

ssh: login ?= app
ssh: ssh-keygen ## log into a node in REGION via ssh (eu-central is default)
	$(info Logging into node via ssh on region ${REGION})
	ssh -v -l ${login} -i ${sshkey} \
	  -o StrictHostKeyChecking=accept-new -o IdentitiesOnly=yes \
	  $(shell ./linode-swarm.sh ip ${REGION})

uptime: inventory ## show uptime of all running nodes
	$(info Showing uptime for all running nodes)
	$(call ANSIPLAY, uptime.yaml)

reboot: inventory
	$(call ANSIPLAY, reboot.yaml)

restart: inventory
	$(info ANSIPLAY, restart.yaml)
