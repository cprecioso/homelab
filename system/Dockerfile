# syntax=docker/dockerfile:1

FROM quay.io/fedora/fedora-coreos:stable AS base

COPY <<EOF /etc/selinux/config
SELINUX=disabled
EOF

ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
RUN rpm-ostree install tailscale && ostree container commit
RUN systemctl enable tailscaled

RUN rpm-ostree install cockpit cockpit-files cockpit-networkmanager cockpit-ostree cockpit-podman cockpit-storaged && ostree container commit
RUN systemctl enable cockpit.socket

COPY --link ./hass/quadlet/* /etc/containers/systemd/
COPY --link ./portainer/quadlet/* /etc/containers/systemd/

COPY --link ./tailscale/systemd/* /etc/systemd/system/
RUN systemctl enable taiscale-config.service
