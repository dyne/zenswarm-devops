![Zenswarm](docs/zenswarm.svg)


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
- [nodejs v16](https://nodejs.org)
- [supervisord](http://supervisord.org/)


When you clone this repository you are into the orchestration terminal.

Type `make` for an overview of orchestration commands.

```
Usage:
  make <target>

General
  help             Display this help.
  regions          list available regions
  ssh-keygen       generate a dedicated ssh keypair here
  ssh-cleanup      clean all fingerprints from known hosts

Node lifecycle
  list             list running nodes (list-ips for IPv4 only)
  all-up           create 11 active nodes, one for each linode region
  teardown         destroy all active nodes
  one-up           create 1 active node in REGION (eu-central is default)

Image operations
  image-init       setup golden image development on linode
  image-build      build the zenswarm golden image on linode
  image-delete     delete the zenswarm golden image on linode

App management
  deploy           deploy the zencode contracts on all available nodes
  announce         announce all nodes to the tracker endpoint
  ssh              log into a node in REGION via ssh (eu-central is default)
  uptime           show uptime of all running nodes
  reboot           reboot all running nodes
```

## Quick Start

1. `make image-init` will configure packer to build a zenswarm image
2. `make image-build` will build a zenswarm golden image on linode
3. `make one-up` will summon a single test node (default eu-central)
4. `make ssh` to ssh into a single node (default eu-central)
4. `make teardown` will destroy all nodes running
5. `make all-up` will summon a swarm of nodes in different regions
6. Place your zencode contracts in roles/install.zip
7. `make deploy` will deploy the zencode contracts on all servers
8. `make uptime` will show the uptime and memory of all servers

Zencode contracts can be uploaded in the form of a .ZIP file as
provided by [Apiroom](https://apiroom.net).

## Swarm Management

Use `make list` to have a list of active nodes and `make ssh` to
login into one of them individually, would there be some debugging
need.

The use of `make uptime` should be enough to see the usage of all
nodes, we are working to equip the swarm with more metrics and a
full report of operations.

![Swarm of keys](docs/keyswarm.png)

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

