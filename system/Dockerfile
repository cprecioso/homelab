# syntax=docker/dockerfile:1

FROM quay.io/fedora/fedora-coreos:stable AS base

COPY <<EOF /etc/selinux/config
SELINUX=disabled
EOF

ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
RUN dnf install -y tailscale && dnf clean all
RUN systemctl enable tailscaled

RUN dnf install -y \
    cockpit \
    cockpit-files \
    cockpit-machines \
    cockpit-networkmanager \
    cockpit-ostree \
    cockpit-podman \
    cockpit-selinux \
    cockpit-storaged \
    cockpit-system \
  && dnf clean all
RUN systemctl enable cockpit.socket

COPY --link ./hass/quadlet/* /etc/containers/systemd/
COPY --link ./portainer/quadlet/* /etc/containers/systemd/
COPY --link ./tsidp/quadlet/* /etc/containers/systemd/

COPY --link ./tailscale/systemd/* /etc/systemd/system/
RUN systemctl enable tailscale-config.service

RUN systemctl enable podman-restart.service
