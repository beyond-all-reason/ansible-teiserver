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

## External dependencies

Teiserver has a few external dependencies that are not managed by this playbook. Here we document what those are and how to configure them e.g. for local testing.

### Email

Teiserver uses email for sending notifications via any SMTP server.

For local testing you can use [smtp4dev](https://github.com/rnwood/smtp4dev) that will simulate an SMTP server and you can browse all the emails sent to it via web interface.

You can run it like:

```
sudo podman run --rm -p 3000:80 -p 2525:25 rnwood/smtp4dev --tlsmode=StartTls
```

and configure the variables to point to port `2525` at whatever ip you are running it on.

### Discord

You have to create a new Discord server and Discord bot to test this integration.

1. Create a new Discord server with the big "+" button on the server list
    1. Get GuildID: Go to settings -> Widget -> Server ID
2. Go to https://discord.com/developers/applications and create new application
    1. Go to Bot
    2. Name your bot something
    3. Click reset token to get the access token you will need for configuration
    4. Make sure “Message Content Intent” is enabled
    5. Go to Oauth2, and in OAuth2 URL Generator
        - Scopes: bot
        - Bot Permissions: Administrator
    6. Open the generated URL and install it in the test server
3. Fill in the 3 variables in the playbook and deploy new version
4. In the Teiserver web interface (I needed to restart the server for some of those changes to take effect):
    - Admin -> Site Config -> Discord: Enable the bridge and insert the channel IDs you want to bridge
    - Admin -> Text Callbacks: Add new text callbacks for the `/textcb` command on Discord

### GeoIP

**TODO**

### Autohost server

This isn't really a dependency, but it's quite useful for testing running of games etc. There are multiple ways it can be set up, but if you are using this playbook to setup prod-like environment, you can use the instruction in https://github.com/beyond-all-reason/ansible-spads-setup playbook to setup prod-like SPADs environment: It plays well with this one.
