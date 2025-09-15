# Server Kicker

`kicker` is a user on the server that is only allowed to restart the `teiserver` service, with no other permissions. While full server access is restricted to a few people, a broader group of BAR contributors across different time zones can use the `kicker` account. Access to the `kicker` user is controlled by SSH keys, which are synchronized every 30 minutes from the public keys of configured GitHub users.

## Restart Procedure

This procedure outlines when and how to use the `kicker` account to restart the **production server** (`server4.beyondallreason.info`). The `kicker` user should only be used when the `teiserver` service is unresponsive and primary maintainers are not available.

### 0. Prerequisites

You must be a trusted BAR contributor with access to the `kicker` user and you finished the ["New kicker user configuration"](#new-kicker-user-configuration) instructions below.

### 1. Assess the impact

Verify that the server is indeed unresponsive or is behaving in a very unexpected way:

- The website does not load
- There are no lobbies showing up for multiple minutes
- The lobbies are in a very bad shape overall
- Nobody can connect to the lobbies or gets dropped from them
- People are being disconnected from the server continuously
- Overall, [`#main`] is on fire

### 2. Communicate

Contact the primary owners (Beherith, Marek, Lexon) on the [`#infrastructure`] Discord channel. If none of them respond, or it's obviously e.g. 4am for them, you might need to restart the server yourself.

Use the [`#infrastructure`] channel for the coordination on the issue, but also check the [`#dev-main`], [`#teiserver-spads`], [`#dev-discussion`] and [`#dev-organization`] channels to see if there is any ongoing work that might be related to the issue.

> [!IMPORTANT]  
> **You must communicate what you are doing in the [`#infrastructure`] channel.** You might be the only person that can help, so it's important to keep everyone informed and allow them to catch up on the situation as they become available.

### 3. Restart the Service

#### Step 1: Connect to the server

SSH into the production server as the `kicker` user.

```
ssh kicker@server4.beyondallreason.info
```

> [!TIP]
> `server5.beyondallreason.info` is an integration server where you can test this procedure without affecting production.

#### Step 2: Check the service status

Upon connecting, the current status of the `teiserver` service will be displayed. It will look something like this:

```
● teiserver.service - Teiserver Elixir Application
     Active: active (running) since Mon 2025-09-15 15:21:39 UTC; 1h 4min ago
     Memory: 16.3G (peak: 16.6G)
```

Review the `Active` line to see how long the service has been running.

#### Step 3: Decide and restart

If the service is `active (running)` only for a few minutes, a restart is unlikely to help as it was likely already restarted or crashed recently. The service can be unstable initially, especially under heavy load.

- It does not make sense to restart less than 5 minutes after the last restart.
- The situation is unlikely to improve on its own more than 30 minutes after the last restart.

If you decide to proceed, confirm the restart when prompted. See the demo below.

<img src="kicker-demo.gif" width="700" />

All the restarts are logged with who performed them and when.

#### Step 4: Monitor

After a restart, it may take a few minutes for the service to stabilize. Continue to monitor the situation and report your actions in the [`#infrastructure`] channel.

## New kicker user configuration

1. A server administrator must add your GitHub username to the `kicker_github_users` list in this repository and deploy the change to the servers.
2. You need to have an SSH key. You can follow any online resources to learn about them, e.g., [GitHub's documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/about-ssh), [Arch Linux wiki](https://wiki.archlinux.org/title/SSH_keys), or a YouTube tutorial.
3. You need to add your SSH key to your GitHub account. Follow the [GitHub documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account). If this is done correctly, your keys will be listed at `https://github.com/{your_username}.keys` (e.g., https://github.com/p2004a.keys).
4. Test your access by following the [restart procedure](#restart-procedure) above for the integration server (`server5.beyondallreason.info`). You can also test the connection to the production server, but **do not restart it** just to test your access.

> [!NOTE]
> It may take up to 30 minutes for your access to be activated, as the keys are synchronized every 30 minutes.

[`#main`]: https://discord.com/channels/549281623154229250/549281623577722899
[`#infrastructure`]: https://discord.com/channels/549281623154229250/1273218599653343262
[`#dev-main`]: https://discord.com/channels/549281623154229250/549282166543089674
[`#teiserver-spads`]: https://discord.com/channels/549281623154229250/564591092360675328
[`#dev-discussion`]: https://discord.com/channels/549281623154229250/724293659809284137
[`#dev-organization`]: https://discord.com/channels/549281623154229250/643197947441315840
