FROM quay.io/coreos/butane:release AS config
WORKDIR /work
COPY --link ./config.bu /work/config.bu
RUN butane --pretty --strict < ./config.bu > ./config.ign

FROM quay.io/fedora/fedora-coreos:stable

ADD https://pkgs.tailscale.com/stable/fedora/tailscale.repo /etc/yum.repos.d/tailscale.repo
RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree install tailscale
RUN systemctl enable tailscaled.service
RUN ostree container commit

RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree install cockpit
RUN systemctl enable cockpit.socket
RUN ostree container commit

RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree override remove podman toolbox containerd moby-engine runc
RUN ostree container commit

ADD https://download.docker.com/linux/fedora/docker-ce.repo /etc/yum.repos.d/docker-ce.repo
RUN --mount=type=cache,target=/var/cache/rpm-ostree rpm-ostree install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
RUN systemctl enable docker
RUN ostree container commit

COPY --from=config /work/config.ign /usr/share/ignition/config.ign
