# Dependencies

 - ansible
 - ansible-Inventory
 - [hetzner.hcloud](https://docs.ansible.com/ansible/latest/collections/hetzner/hcloud/hcloud_inventory.html#ansible-collections-hetzner-hcloud-hcloud-inventory)

```
python3 -m pip install --user pipx
python3 -m pipx ensurepath
pipx install ansible-base
pipx inject pipx ansible
pipx inject pipx hcloud
```

For mac:

```
brew install ansible
# Activate the virtualenv
source /usr/local/Cellar/ansible/x.x.0/libexec/bin/activate
pip install hcloud
```
