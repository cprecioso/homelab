# syntax=docker/dockerfile:1

FROM docker.io/library/caddy:2.8.1-builder-alpine AS builder

RUN --mount=type=cache,target=/go/pkg/mod/ xcaddy build --with github.com/caddy-dns/cloudflare

FROM docker.io/library/caddy:2.8.1-alpine

COPY --from=builder /usr/bin/caddy /usr/bin/caddy
COPY --link ./Caddyfile /etc/caddy/Caddyfile
