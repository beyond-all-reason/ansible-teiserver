# Runbook

A set of step by step guides for how to execute some procedures.

## Backups

### Taking backup

The backup is taken automatically periodically by the `take-db-backup` systemd service. To take the backup manually, you can start the service, or manually execute the scripts it runs:

```
sudo tei-backup-take
```

The script uploads the backup file using rclone to the storage configured in `/usr/local/etc/backup/rclone.conf`.

### Copying/downloading backups

It overall depends where the backups are stored. One way to do it is:

1. Get rclone base command, example:

   ```
   $ cat /usr/local/bin/tei-backup-take | grep rclone
   rclone --config /usr/local/etc/backup/rclone.conf copyto /var/tmp/backup/$BACKUP_FILE "backup:/var/backups/teiserver/$BACKUP_FILE"
   ```

   The important part is the `backup:/var/backups/teiserver/`, that can be different for you, and we will use in the next steps.

2. Modify rclone invocation to list the backups:

   ```
   sudo rclone --config /usr/local/etc/backup/rclone.conf ls "backup:/var/backups/teiserver/"
   ```

3. Download the backup:

   ```
   sudo rclone --config /usr/local/etc/backup/rclone.conf copy "backup:/var/backups/teiserver/teiserver_prod-20240418222419.dump.zst" .
   ```

### Restoring backup

Assuming that you have the backup file e.g. `teiserver_prod-20240418222419.dump.zst` locally, you can restore it with:

1. Make sure that teiserver is not running, and stop it if it is

   ```
   sudo systemctl stop teiserver
   ```

2. Consider [taking the backup](#taking-backup) of the database before replacing it with the restored version.

3. Restore the backup

   This command doesn't ask for any confirmation, it drops the database and recreates it from the backup.

   ```
   zstdcat teiserver_prod-20240418222419.dump.zst | sudo -i -u postgres pg_restore -d postgres --clean --create
   ```

4. Start the teiserver

   ```
   sudo systemctl start teiserver
   ```

### Streaming copy of database

To speedup the migration of the database from one server to another, if we want to minimize the time, the taking backup, compressing, sending, and then restoring can be pipelined into a single invocation.

1. SSH into the source server

   Note that for the next command, ssh needs to be able to connect to the destination server without asking for a password. You can use ssh agent forwarding or sshpass to achieve that. The sudo command on the destination server needs to be able to run without asking for a password too.

2. Run the following command on the source server:

   ```
   pg_dump -U teiserver_prod -d teiserver_prod -Fc -Z0 \
      | zstd -T4 --long -9 --stdout \
      | tee backup.dump.zst \
      | ssh user@target-server \
         "zstdcat | sudo -i -u postgres pg_restore -d postgres --clean --create"
   ```

## New host setup

Currently, when we setup new servers, they are not yet provisioned via cloud-init, which means that a bunch of things are done manually and can differ between hosts. Maybe some of them should be moved to playbook too. For now we list the list of commands for copy pasting.

### Create users

Assuming one has the root account access, and there aren't any user account, the steps to create a new user are like:

```
NEW_USER={username}
GITHUB_NAME={githubusername}
adduser --disabled-password --gecos "" $NEW_USER
usermod -a -G sudo $NEW_USER
sudo -u $NEW_USER mkdir /home/$NEW_USER/.ssh
sudo -u $NEW_USER chmod og-rwx /home/$NEW_USER/.ssh
sudo -u $NEW_USER curl -L https://github.com/$GITHUB_NAME.keys > /home/$NEW_USER/.ssh/authorized_keys
```

This gives access to the server via ssh keys.

#### Option 1: passwordless sudo

Create group for users that can use sudo without pass and configure sudo:

```
addgroup --system passwordless
cat > /etc/sudoers.d/91-passwordless <<EOF
# Members or passwordless group don't require password for sudo
%passwordless ALL=(ALL:ALL) NOPASSWD:ALL
EOF
```

Then add users to it via:

```
usermod -a -G passwordless $NEW_USER
```

#### Option 2: Configure passwords

Generate random password

```
dd status=none if=/dev/urandom bs=1 count=256 | sha256sum
```

Set the password for the user:

```
passwd $NEW_USER
```

And ask them to change it on the first login.

### Harden SSH

It's good to disable direct root login and password based login

```
cat > /etc/ssh/sshd_config.d/90-harden.conf <<EOF
PermitRootLogin no
PubkeyAuthentication yes
PasswordAuthentication no
EOF
```
