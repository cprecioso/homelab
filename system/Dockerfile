# syntax=docker/dockerfile:1

FROM quay.io/fedora/fedora-coreos:stable AS base

# Disable SELinux
COPY --link ./selinux/selinux.conf /etc/selinux/config

# Utility programs
RUN dnf install -y screen ncdu glibc-langpack-en glibc-langpack-es && dnf clean all

# Replace Docker with Podman
RUN dnf remove -y docker-cli moby-engine && dnf clean all
RUN dnf install -y podman-docker && dnf clean all
RUN systemctl enable podman-restart.service

# Install Tailscale
ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
RUN dnf install -y tailscale && dnf clean all
RUN systemctl enable tailscaled

# Add Tailscale configuration unit
COPY --link ./tailscale/systemd/* /etc/systemd/system/
RUN systemctl enable tailscale-config.service

# Allow IP forwarding for Tailscale
COPY --link ./tailscale/ip-forwarding.conf /etc/sysctl.d/99-tailscale.conf

# Install Cockpit and plugins
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

# Add Rclone and FUSE
RUN dnf install -y rclone fuse && dnf clean all

# Copy quadlets
COPY --link ./hass/quadlet/* /etc/containers/systemd/
COPY --link ./portainer/quadlet/* /etc/containers/systemd/
COPY --link ./tsidp/quadlet/* /etc/containers/systemd/
COPY --link ./paperless/quadlet/* /etc/containers/systemd/

# Copy extra Paperless files
COPY --link ./paperless/systemd/* /etc/systemd/system/

# Enable bootc automatic updates
COPY --link ./bootc/systemd/* /etc/systemd/system/
RUN systemctl enable bootc-fetch-apply-updates.timer

# Enable daily Podman image pruning
COPY --link ./podman/systemd/* /etc/systemd/system/
RUN systemctl enable podman-image-prune.timer

# Install Claude
COPY --link ./claude/claude-code.repo /etc/yum.repos.d/claude-code.repo
RUN dnf install -y claude-code && dnf clean all

RUN bootc container lint
