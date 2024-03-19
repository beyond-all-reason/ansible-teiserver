#!/bin/bash

# Simple dynamic inventory script that resolves the IP of the test teiserver LXD container

SUDO=
if ! id -nG | grep -qw lxd
then
    SUDO=sudo
fi

IP=$(command -v lxc &> /dev/null && $SUDO lxc list -f csv -c 4 teiserver-test | grep -E 'eth|enp' | cut -d' ' -f1)

# For the case when used doen't have lxc installed at all or the container is not running
if [[ -z "$IP" ]]
then
cat <<EOF
{
    "_meta": {
        "hostvars": {}
    }
}
EOF
else
cat <<EOF
{
  "_meta": {
    "hostvars": {
      "test": {
        "ansible_host": "$IP",
        "ansible_user": "ansible",
        "ansible_ssh_private_key_file": "test.ssh.key"
      }
    }
  },
  "all": {
    "children": [
      "dev"
    ]
  },
  "dev": {
    "hosts": [
      "test"
    ]
  }
}
EOF
fi
