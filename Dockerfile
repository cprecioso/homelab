# syntax=docker/dockerfile:1

# Create Fedora CoreOS image
FROM quay.io/fedora/fedora-coreos:stable

# Install Tailscale
ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree install tailscale
RUN systemctl enable tailscaled.service
RUN ostree container commit

# Install Cockpit
RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree install cockpit
RUN systemctl enable cockpit.socket
RUN ostree container commit

# Uninstall Podman
RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree override remove podman toolbox containerd moby-engine runc
RUN ostree container commit

# Install Docker
ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
RUN systemctl enable docker
RUN ostree container commit

# Change Zincati for systemd auto-update
RUN systemctl mask zincati

# Enable systemd auto-update
COPY --link ./autoupdate/ /
RUN systemctl enable autoupdate-host.timer
