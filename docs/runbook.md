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
