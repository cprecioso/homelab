## Installation

On an `rpm-ostree` based system, do the following:

1. Write the `/etc/credstore/tailscale-authkey` file:

   ```
   tskey-auth-xxxxxx
   ```

2. Rebase to this system image:

   ```bash
   rpm-ostree rebase ostree-image-signed:registry:ghcr.io/cprecioso/homelab-system:latest
   systemctl reboot
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
