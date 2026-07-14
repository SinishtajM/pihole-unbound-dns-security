#!/usr/bin/env bash

# Add a stable IPv6 address to the Pi-hole interface.
# Configuration is read from /etc/default/pihole-ipv6 by systemd.

set -euo pipefail

: "${PIHOLE_IPV6_INTERFACE:?Set PIHOLE_IPV6_INTERFACE in /etc/default/pihole-ipv6}"
: "${PIHOLE_IPV6_ADDRESS:?Set PIHOLE_IPV6_ADDRESS in /etc/default/pihole-ipv6}"

for _ in {1..10}; do
    if ip link show "$PIHOLE_IPV6_INTERFACE" >/dev/null 2>&1; then
        break
    fi
    sleep 1
done

if ! ip link show "$PIHOLE_IPV6_INTERFACE" >/dev/null 2>&1; then
    printf 'Interface not found: %s\n' "$PIHOLE_IPV6_INTERFACE" >&2
    exit 1
fi

ip -6 address replace "$PIHOLE_IPV6_ADDRESS" dev "$PIHOLE_IPV6_INTERFACE"
