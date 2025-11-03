## Installation

On an `rpm-ostree`/`bootc` based system, do the following:

1. Write the `/etc/credstore/tailscale-authkey` file:

   ```
   tskey-auth-xxxxxx
   ```

2. Rebase to this system image:

   ```bash
   bootc switch registry:ghcr.io/cprecioso/homelab-system:latest --apply
   ```

3. Once Home Assistant has been set up, get an access token and write the
   `/etc/credstore/hass-matter-hub-connection`

   ```
   HAMH_HOME_ASSISTANT_URL=http://127.0.0.1:8123/
   HAMH_HOME_ASSISTANT_ACCESS_TOKEN=mytoken
   ```

4. Reboot the system:

   ```bash
   systemctl reboot
   ```
