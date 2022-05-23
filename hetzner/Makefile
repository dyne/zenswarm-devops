.DEFAULT_GOAL := help
.PHONY: help
help: ## ℹ️ Show this help message
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}'

inventory: ## ☁️ Show the inventory in hetzner
	ansible-inventory -i testnet.hcloud.yml --graph

list: ## 📙 List of the servers details
	ansible-inventory -i testnet.hcloud.yml --list

ip: ips
ips: ## 🗺 List the IP adresses of the servers
	ansible-playbook plyabooks/debug.yml

server: create
create: NAME := $(shell tr -dc A-Za-z0-9 </dev/urandom | head -c 10)
create: LOCA := $(shell hcloud datacenter list -o columns=location -o noheader | shuf -n 1)
create: ## 🖥 Create a new server on hetzner
	hcloud server create --name ${NAME} --image debian-11 --type cx11 --location ${LOCA} --ssh-key fuffola

deploy: ## 🚀 Deploy the server
	ansible-playbook plyabooks/deploy.yml