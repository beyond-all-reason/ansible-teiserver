#!/bin/bash

# Simple dynamic inventory script that resolves the IP of the test teiserver Incus container

EMPTY_CONFIG='{"_meta": {"hostvars": {}}}'

if [ ! -f .incus-integration-on ]
then
  echo $EMPTY_CONFIG
  exit
fi

IP=$(command -v incus &> /dev/null && incus list -f csv -c 4 teiserver-test | grep -E 'eth|enp' | cut -d' ' -f1)

# For the case when used doen't have Incus installed at all or the container is not running
if [[ -z "$IP" ]]
then
  echo $EMPTY_CONFIG
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
