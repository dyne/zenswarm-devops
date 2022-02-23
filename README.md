# Zenswarm

Orchestrating Zenroom VMlets as a Swarm of Oracles

![image](https://user-images.githubusercontent.com/148059/149499339-af8c430d-6d3c-4dd7-9029-6bf514867b56.png)

# Requirements

To be able to install a swarm one needs a global cloud provider, this
repository is pre-configured to use Linode's nano servers placed in 11
different regions of the world.

To be installed on the orchestration terminal:

- GNU make
- ansible
- [zenroom](zenroom.org)
- [linode-cli](https://www.linode.com/products/cli/)

To be installed on each node in the swarm:

- [zenroom](zenroom.org)
- [restroom-mw](https://github.com/dyne/restroom-mw)
- [nodejs v14](https://nodejs.org)
- [supervisord](http://supervisord.org/)


When you clone this repository you are into the orchestration terminal.

Type `make` for an overview of orchestration commands.

```
Usage:
  make <target>

General
  help             Display this help.
  inventory        update and show list of active nodes
  regions          list available regions
  ssh-keygen       generate a dedicated ssh keypair here

Node lifecycle
  all-up           create 11 active nodes, one for each linode region
  all-down         destroy all active nodes
  one-up           create one active node in REGION (eu-west is default)
  one-down         destroy one active node in REGION (eu-west is default)

Node operations
  install          install the zencode api server on all available nodes
  deploy           install the zencode api server on all available nodes
  ssh              log into a node in REGION via ssh (eu-west is default)
  uptime           show uptime of all running nodes
```

## Quick Start

1. `make all-up` will summon the swarm servers
2. `make install` will install all servers with zenswarm
3. `make deploy` will install the zencode contracts on all servers

Zencode contracts can be uploaded in the form of a .ZIP file as
provided by [Apiroom](https://apiroom.net). Easy peasy lemon squeezy.

## Swarm Management

Use `make inventory` to have a list of active nodes and `make ssh` to
login into one of them individually, would there be some debugging
need.

The use of `make uptime` should be enough to see the usage of all
nodes, we are working to equip the swarm with more metrics and a
full report of operations.

# Acknowledgements

	Zenswarm is Copyleft (ɔ) 2022 Dyne.org foundation, Amsterdam

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU Affero General Public License as
    published by the Free Software Foundation, either version 3 of the
    License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Affero General Public License for more details.

    You should have received a copy of the GNU Affero General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
	
