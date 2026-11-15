# Security Policy

## System and Scope

This repository defines an internet-facing static website hosted on Google
Cloud and delivered through Cloudflare. Covered components are the static site,
Nginx configuration, Terraform-managed cloud infrastructure, Cloudflare Tunnel,
DNS records, zone settings, WAF rules, GitHub workflows, and deployment
credentials.

## Threat Model and Trust Boundaries

Internet visitors and all HTTP request data are untrusted. Cloudflare is the
only intended public application entry point.

The GCP origin, Terraform state, GitHub environments, cloud accounts, API
credentials, Tunnel token, registrar account, and DNS control plane are trusted
security boundaries.

Attackers may attempt to bypass Cloudflare, expose or take over the origin,
create dangling DNS records, steal deployment credentials, weaken TLS or WAF
settings, modify public content, or exhaust availability.

## Security Invariants

- The origin must have no inbound Internet access.
- No origin address may be published in public DNS.
- Site DNS records must remain proxied through Cloudflare and reference the
  managed Tunnel.
- Tunnel configuration must end with a fail-closed `http_status:404` rule.
- Secrets must never be committed or included in repository files, examples,
  tests, issues, pull requests, workflow YAML, logs, or command-line arguments.
- Terraform state, populated variable files, environment files, and saved
  plans must never be committed.
- Cloud and GitHub permissions must follow least privilege.
- Every external GitHub Action must be pinned to its full 40-character commit
  SHA. Mutable version tags, branches, and `main` are prohibited.
- HTTPS redirection and a minimum TLS version of 1.2 must remain enabled.
- DNS records must be removed before their backing service is decommissioned.
- The static-site WAF rule must be reviewed before forms, write methods, or
  APIs are introduced.

## Secret and Credential Management

Use GitHub Environment secrets or an approved external secret manager for
sensitive values required by automation. Repository and Terraform variables
may contain non-secret configuration, but variables are not a security
boundary and must never contain plaintext credentials.

Prefer GitHub OpenID Connect and short-lived cloud roles for AWS, Azure, and
GCP. Do not create long-lived cloud access keys when workload identity is
available.

Secrets include, but are not limited to:

- AWS access keys, secret keys, session tokens, passwords, and private keys.
- GCP service-account keys, OAuth secrets, refresh tokens, and private keys.
- Azure client secrets, certificates, storage keys, SAS tokens, and publish
  profiles.
- Cloudflare API tokens, global API keys, Origin CA private keys, and Tunnel
  tokens.
- GitHub personal access tokens, deploy private keys, application private keys,
  and webhook secrets.
- Database passwords, connection strings, signing keys, TLS or SSH private
  keys, registrar recovery codes, MFA seeds, and backup codes.
- Terraform state and saved plan files that contain sensitive provider values.

Cloud account IDs, Azure subscription or tenant IDs, GCP project IDs,
Cloudflare account or zone IDs, and role ARNs are identifiers rather than
authentication secrets. Store them as secrets when infrastructure metadata
must remain confidential.

If a credential is exposed, revoke or rotate it immediately. Removing the file
or rewriting Git history does not make the credential safe to reuse.

## Reportable Findings and Severity Context

Report vulnerabilities that realistically break an invariant or cross a trust
boundary. Examples include direct origin reachability, credential exposure,
unauthorized infrastructure changes, public content takeover, exploitable
dangling DNS, Cloudflare bypass, excessive workflow permissions, or material
weakening of TLS or request filtering.

Severity should reflect Internet reachability, required privileges, affected
assets, persistence, and whether an attacker can control content, credentials,
DNS, GitHub automation, or cloud infrastructure.

## Out of Scope, Exclusions, and Accepted Risk

No vulnerability classes are intentionally excluded. The single-VM origin is a
known availability limitation of this portfolio demonstration, but bypassing
its network or Cloudflare controls remains reportable.

Do not test against infrastructure you do not own, perform denial-of-service
testing, access other users' data, or use social engineering.

## Known Limitations and Compensating Controls

- The starter deployment uses one VM and one Tunnel connector.
- The lower-cost mode assigns the VM an external IP for outbound connectivity,
  but denies inbound traffic and never publishes that address.
- Cloudflare Security Insights and GitHub secret scanning are detection
  backstops and may not identify every unsafe condition.
- Terraform dependency ordering and manual teardown verification remain
  required.
- Terraform state contains a sensitive Tunnel token and requires encrypted,
  access-controlled storage.

## Reporting

Use GitHub's private “Report a vulnerability” flow when enabled. If private
reporting is unavailable, contact the maintainer through their GitHub profile
without placing secrets or exploit details in a public issue.
