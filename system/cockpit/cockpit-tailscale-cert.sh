#!/bin/sh
# Fetch (or renew) this machine's Tailscale TLS certificate for Cockpit, and
# restart Cockpit only if the certificate changed.
set -eu

dir=/etc/cockpit/ws-certs.d
fqdn=$(tailscale status --json | jq -r .Self.DNSName)
fqdn=${fqdn%.}

before=$(sha256sum "$dir/tailscale.cert" 2>/dev/null || true)
tailscale cert --cert-file "$dir/tailscale.cert" --key-file "$dir/tailscale.key" "$fqdn"
after=$(sha256sum "$dir/tailscale.cert")

if [ "$before" != "$after" ]; then
  systemctl try-restart cockpit.service
fi
