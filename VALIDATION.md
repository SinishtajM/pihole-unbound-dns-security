# Tested Environment and Validation Report

This report documents the software versions, validation methods, expected outcomes, and observed results for the working Pi-hole and Unbound deployment.

The commands use localhost or public DNS test infrastructure. Live LAN addresses, IPv6 prefixes, hostnames, client names, and other environment-specific identifiers remain redacted.

## Tested Environment

The following versions were captured from the working DNS LXC during final validation on **July 13, 2026**:

| Component | Tested version | Validation source |
|---|---|---|
| Debian | 12 (Bookworm) | `/etc/os-release` |
| Pi-hole Core | v6.4.3 | `/etc/pihole/versions` |
| Pi-hole Web | v6.6 | `/etc/pihole/versions` |
| Pi-hole FTL | v6.7 | `/etc/pihole/versions` |
| Unbound | 1.17.1 | `unbound -V` |

Additional deployment checks confirmed that:

- The live Unbound configuration passed `unbound-checkconf` with no errors.
- `pihole-ipv6.service` was enabled and active.
- The DNS LXC remained unprivileged.
- Windows received the intended Pi-hole IPv4 and IPv6 DNS server addresses.

Version information is included so reviewers can distinguish the tested deployment from later software behavior, configuration formats, or defaults.

## Validation Scope

Validation was performed from two locations:

1. **DNS LXC:** service state, listening sockets, local Pi-hole resolution, direct Unbound resolution, DNSSEC, direct root-server reachability, and forwarding behavior.
2. **Windows client:** IPv4 and IPv6 DNS assignment and client access to Pi-hole.

The original working-deployment evidence predates the expanded public [`dns-health`](scripts/dns-health) script. The published script was sanitized and passed Bash syntax validation, but it was not rerun against the live DNS LXC after explicit result handling, positive-answer validation, configurable listener checks, exact A-root identity validation, and the TCP root-server test were added.

## Status Definitions

| Status | Meaning |
|---|---|
| Passed | Directly observed in the working deployment or captured evidence |
| Verified | Confirmed as a configuration or platform property |
| Added to published script | Implemented in the public script but not included in the original captured live run |

## Results

| Validation | Command or method | Expected success condition | Status |
|---|---|---|---|
| Pi-hole service | `systemctl is-active pihole-FTL` | Service reports `active` | Passed |
| Unbound service | `systemctl is-active unbound` | Service reports `active` | Passed |
| Pi-hole DNS listener | `ss -H -lntu` | DNS listener is present on port `53` | Passed |
| Unbound local listener | `ss -H -lntu` | Listener is present on `127.0.0.1:5335` | Passed |
| Unbound configuration | `unbound-checkconf` | Configuration contains no errors | Passed |
| Pi-hole normal resolution | `dig @127.0.0.1 pi-hole.net A` | Response status is `NOERROR` and the answer count is greater than zero | Passed |
| Pi-hole blocking | `dig @127.0.0.1 doubleclick.net A` | Pi-hole returns a recognized blocking response such as `NXDOMAIN`, an empty answer, or `0.0.0.0` | Passed |
| Unbound recursive resolution | `dig @127.0.0.1 -p 5335 pi-hole.net A` | Response status is `NOERROR` and the answer count is greater than zero | Passed |
| Broken DNSSEC rejection | `dig @127.0.0.1 -p 5335 fail01.dnssec.works A` | Response status is `SERVFAIL` | Passed |
| Valid DNSSEC authentication | `dig +dnssec @127.0.0.1 -p 5335 dnssec.works A` | Response is `NOERROR`, includes the `ad` flag, and has a positive answer count | Passed |
| Root-server UDP access | `dig @198.41.0.4 . NS +norec` | Authoritative `aa` flag is present and `ra` is absent | Passed |
| Root-server TCP access | `dig @198.41.0.4 . NS +norec +tcp` | Authoritative `aa` flag is present and `ra` is absent | Added to published script |
| Root-server identity | `dig @198.41.0.4 version.bind TXT CH +norec +short` | Response exactly matches the configured A-root identity, `ATLAS` | Passed (`ATLAS`) |
| Pi-hole forwarding to Unbound | Recent Pi-hole log inspection | Forwarding entries reference `127.0.0.1#5335` | Passed |
| Stable IPv6 boot service | `systemctl is-enabled --quiet pihole-ipv6.service` and `systemctl is-active --quiet pihole-ipv6.service` | Service is enabled and active | Passed |
| Windows client DNS assignment | `Get-DnsClientServerAddress` | Active client interface lists the intended Pi-hole IPv4 and IPv6 DNS addresses without an external DNS fallback | Passed |
| Container isolation | Proxmox LXC configuration review | Container is configured as unprivileged | Verified |

## DNSSEC Interpretation

The two DNSSEC tests validate opposite outcomes:

- A deliberately broken signed domain must fail with `SERVFAIL`.
- A valid signed domain must resolve with a positive answer and include the authenticated-data (`ad`) flag.

Testing both outcomes is important. A normal successful lookup alone does not prove that invalid DNSSEC data is being rejected.

## Root-Server Interpretation

A direct nonrecursive query to a root server should return an authoritative response:

```text
flags: qr aa
```

The response should not include the recursion-available (`ra`) flag. During troubleshooting, the unexpected presence of `ra` exposed router-level DNS interception. After the router feature was disabled, the captured UDP root-server test returned the expected authoritative behavior.

The `version.bind` CHAOS-class query returned the expected A-root identity, `ATLAS`, providing additional evidence that the query reached A-root directly. The published health-check script requires an exact match to the configured identity. A separate TCP test is also included and should be run during the next live deployment validation.

## IPv4 and IPv6 Scope

IPv6 client access and Unbound's outbound recursion transport are separate design choices:

- Clients can query Pi-hole over IPv4 or IPv6.
- Pi-hole forwards allowed requests locally to Unbound on `127.0.0.1:5335`.
- The published Unbound configuration uses IPv4 for outbound recursive queries.

This design still prevents IPv6-capable clients from bypassing Pi-hole through an ISP or router-provided IPv6 DNS resolver.

## Evidence Mapping

| Evidence | What it demonstrates |
|---|---|
| [`screenshots/dns-health-output.png`](screenshots/dns-health-output.png) | Original working-deployment health-check output |
| [`screenshots/unbound-dnssec-tests.png`](screenshots/unbound-dnssec-tests.png) | Broken DNSSEC rejection and valid DNSSEC authentication |
| [`screenshots/root-server-test.png`](screenshots/root-server-test.png) | Direct authoritative UDP root-server response |
| [`screenshots/windows-dns-client-settings.png`](screenshots/windows-dns-client-settings.png) | Windows IPv4 and IPv6 DNS assignment |
| [`screenshots/pihole-query-log-blocked-domain.png`](screenshots/pihole-query-log-blocked-domain.png) | Pi-hole blocking of the test domain |
| [`screenshots/pihole-upstream-unbound.png`](screenshots/pihole-upstream-unbound.png) | Pi-hole forwarding allowed queries to local Unbound |

The public script expands the original health check with explicit pass, warning, and failure handling, a nonzero critical-failure exit code, positive-answer validation, configurable listener checks, an expected A-root identity check, and separate UDP and TCP root-server checks.
