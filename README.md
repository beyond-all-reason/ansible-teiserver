# Ansible playbook for teiserver

This is an [Ansible](https://en.wikipedia.org/wiki/Ansible_(software)) playbook for setting up [Teiserver](https://github.com/beyond-all-reason/teiserver/) instance for BAR.

## Usage

If you are trying to set up and test things locally and you don't have access to BAR production instance, first see the [Local testing](#local-testing) section. If you have access to the server set up with this playbook and you want to figure out how to use it, see the [Server usage](#server-usage) section.

### Playbook

#### Vault

When running against the prod instances, secrets are stored in files encrypted with ansible-vault, for example [group_vars/prod/vault.yml](group_vars/prod/vault.yml). Check out [the official guide](https://docs.ansible.com/ansible/latest/vault_guide/vault_encrypting_content.html#encrypting-files-with-ansible-vault) for how to view and edit them.

For running the playbook against the prod instances, you will need the vault password. You have to run Ansible with `--ask-vault-pass` flag and provide the password when prompted or you can store it in a file (Please put it only in something like [tmpfs](https://en.wikipedia.org/wiki/Tmpfs)!) and point Ansible at it with `--vault-password-file` flag or `ANSIBLE_VAULT_PASSWORD_FILE` environment variable.

#### Running

Currently there is only one playbook that sets up the whole server. You can run it against the `main` instance to check if everything is up to date with:

```
ansible-playbook -l main play.yml --check --diff
```

Then drop the `--check` flag to actually apply the changes.

#### Tags

It's possible to run only selected part of the playbook with the usage of tags. You can fetch the list of tags with:

```
ansible-playbook play.yml --list-tags
```

and then run only selected part with:

```
ansible-playbook -l main play.yml --tags database,teiserver
```

### Server usage

The playbook will setup the server with:

- `deploy` user for building and deploying the Teiserver from the main branch
- `/home/deploy/prod-data` for out-of-source production configs and data like `prod.sesret.exs` managed fully by the playbook
- `/home/deploy/teiserver-repo` checkout of the Teiserver repository
- `teiserver` systemd service for running the Teiserver
- A set of `tei-*` scripts for managing the deployments.

The users should connect to the server via their own individual user, and run commands from them.

The teiserver releases are stored in `/opt/teiserver`, with the current live one being pointed by the `/opt/teiserver/live` symlink. Deploying new code involves effectively:

- Building a new Teiserver [Elixir release](https://hexdocs.pm/mix/Mix.Tasks.Release.html).
- Placing it as a new directory in `/opt/teiserver`.
- Updating the `/opt/teiserver/live` symlink to point to the new release directory.
- Restarting the `teiserver` systemd service.

The `tei-*` scripts are there to help with that process, so in practice, deploying a new version of Teiserver is as simple as:

```
# Pull the latest code to the /home/deploy/teiserver-repo/
tei-pull-deploy-repo
# Build the new release into opt
tei-build
# Deploy the new release
tei-deploy
```

ALl scripts start with `tei-` so you can type `tei-[TAB][TAB]` to see the list of available commands in bash. All of them also support `--help` flag to show the usage.

#### User local code checkout

For the usage on the integration server, each individual user can create their own local checkouts of the Teiserver and deploy them. They don't have to, and really *shouldn't at all* touch the repo in the `/home/deploy/teiserver-repo/` with any local changes.

The example session for on the users could look like:

```
# Clone the teiserver repo
marek@teiserver-test:~$ git clone https://github.com/beyond-all-reason/teiserver.git
marek@teiserver-test:~$ cd teiserver
# Apply the production config to the local checkout
marek@teiserver-test:~/teiserver$ tei-apply-prod-data .
# Do whatever code changes needed
# (...)
# Build the local checkout into new release
marek@teiserver-test:~/teiserver$ tei-build --repo .
# Deploy the new release
marek@teiserver-test:~/teiserver$ tei-deploy
```

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

### Autohost server

This isn't really a dependency, but it's quite useful for testing running of games etc. There are multiple ways it can be set up, but if you are using this playbook to setup prod-like environment, you can use the instruction in https://github.com/beyond-all-reason/ansible-spads-setup playbook to setup prod-like SPADs environment: It plays well with this one.
