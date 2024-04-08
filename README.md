# Ansible playbook for teiserver

**WIP**

## Local testing

### Setup

We use LXD for local testing. Make sure you have it installed and initialized [following the docs](https://documentation.ubuntu.com/lxd/en/latest/). For example for Debian, it's as simple as `sudo apt install lxd && sudo lxd init`.

To create a new container and initialize it via cloud-init, run the following command:

```
sudo lxc launch images:debian/bookworm/cloud teiserver-test < test.lxc.yml && sudo lxc exec teiserver-test -- cloud-init status --wait
```

Then test that it works for ansible:

```
ansible dev -m shell -a 'uname -a'
```

### Usage

Now you can use all the playbooks and roles as usual, just make sure you are targeting the `dev` inventory group or `test` host. For example:

```
ansible-playbook -l dev play.yml
```

To enter into container shell, run the following command:

```
sudo lxc exec teiserver-test -- /bin/bash
```

You can also ssh into it with something like:

```
ssh -i test.ssh.key ansible@$(ansible-inventory --host test | jq -r '.ansible_host')
```

### Cleanup

To stop and remove the container:

```
sudo lxc stop teiserver-test && sudo lxc delete teiserver-test
```
