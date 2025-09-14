# Server Kicker

`kicker` is a user on the server that is only allowed to restart the `teiserver` service, with no other permissions. While full server access is restricted to a few people, a broader group of BAR contributors across different time zones can use the `kicker` account. Access to the `kicker` user is controlled by SSH keys, which are synchronized every 4 hours from the public keys of configured GitHub users.

## Usage

SSH into the server as the `kicker` user:

```
ssh kicker@server5.beyondallreason.info
```

Then, confirm the restart in the prompt. See the demo below.

`server5.beyondallreason.info` is the integration server where you can test this procedure. To restart the production server, connect to `server4.beyondallreason.info`.

![kicker demo](kicker-demo.gif)

## User configuration

1. A server administrator must add your GitHub username to the `kicker_github_users` list in this repository and deploy the change to the server.
2. You need to have an SSH key added to your GitHub account. Follow the [GitHub documentation](https://docs.github.com/en/authentication/connecting-to-github-with-ssh/adding-a-new-ssh-key-to-your-github-account) for instructions.
