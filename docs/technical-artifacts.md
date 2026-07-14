# Technical Artifacts

This directory contains sanitized, parameterized versions of the custom files used in the working Pi-hole and Unbound deployment.

For the complete tested-version inventory, validation commands, expected outcomes, and evidence mapping, see the [Tested Environment and Validation Report](../VALIDATION.md).

## Tested environment

| Component | Tested version |
|---|---|
| Debian | 12 (Bookworm) |
| Pi-hole Core | v6.4.3 |
| Pi-hole Web | v6.6 |
| Pi-hole FTL | v6.7 |
| Unbound | 1.17.1 |
| Validation date | July 13, 2026 |

The live Unbound configuration passed `unbound-checkconf` with no errors. The stable-IPv6 systemd service was both enabled and active when these files were exported.

## Included files

| File | Purpose |
|---|---|
| [`../VALIDATION.md`](../VALIDATION.md) | Documents tested versions, commands, expected results, observed results, and supporting evidence |
| [`scripts/dns-health`](../scripts/dns-health) | Runs repeatable Pi-hole, Unbound, DNSSEC, blocking, IPv4/IPv6, and root-server checks |
| [`scripts/add-pihole-ipv6.sh`](../scripts/add-pihole-ipv6.sh) | Adds a stable IPv6 address to the Pi-hole interface |
| [`configs/systemd/pihole-ipv6.service`](../configs/systemd/pihole-ipv6.service) | Runs the IPv6 helper during boot |
| [`configs/systemd/pihole-ipv6.default.example`](../configs/systemd/pihole-ipv6.default.example) | Example environment file for the stable IPv6 service |
| [`configs/systemd/dns-health.default.example`](../configs/systemd/dns-health.default.example) | Optional configuration for the health-check script |
| [`configs/unbound/pi-hole.conf`](../configs/unbound/pi-hole.conf) | Sanitized Unbound recursive-resolver configuration |

## Installation paths

```text
scripts/dns-health
  -> /usr/local/bin/dns-health

scripts/add-pihole-ipv6.sh
  -> /usr/local/sbin/add-pihole-ipv6.sh

configs/systemd/pihole-ipv6.service
  -> /etc/systemd/system/pihole-ipv6.service

configs/systemd/pihole-ipv6.default.example
  -> /etc/default/pihole-ipv6

configs/systemd/dns-health.default.example
  -> /etc/default/dns-health

configs/unbound/pi-hole.conf
  -> /etc/unbound/unbound.conf.d/pi-hole.conf
```

## Example installation

Review and replace all example addressing before enabling the service.

```bash
sudo install -m 0755 scripts/dns-health /usr/local/bin/dns-health
sudo install -m 0755 scripts/add-pihole-ipv6.sh /usr/local/sbin/add-pihole-ipv6.sh
sudo install -m 0644 configs/systemd/pihole-ipv6.service /etc/systemd/system/pihole-ipv6.service
sudo install -m 0644 configs/systemd/pihole-ipv6.default.example /etc/default/pihole-ipv6
sudo install -m 0644 configs/systemd/dns-health.default.example /etc/default/dns-health
sudo install -m 0644 configs/unbound/pi-hole.conf /etc/unbound/unbound.conf.d/pi-hole.conf

sudo unbound-checkconf
sudo systemctl daemon-reload
sudo systemctl enable --now pihole-ipv6.service
sudo systemctl restart unbound
sudo dns-health
```

## IPv6 design note

The published Unbound configuration uses `do-ip6: no`. This setting controls Unbound's outbound recursive transport only. It does not disable IPv6 access to Pi-hole. IPv6 clients query Pi-hole through its stable IPv6 address, and Pi-hole forwards allowed requests to Unbound over `127.0.0.1:5335`.

## Sanitization

The public files do not include the live IPv4 address, IPv6 prefix, hostname, interface identifiers, client names, or unrelated log data. The IPv6 values in the example environment files are documentation-only examples and must be replaced before use.
