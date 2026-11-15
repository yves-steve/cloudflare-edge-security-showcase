# AGENTS.md

## Purpose

This repository is a public portfolio project demonstrating a small static site on Google Cloud behind Cloudflare. Keep the implementation understandable to someone learning cloud security and infrastructure as code.

## Repository map

- `site/`: static site, Nginx configuration, and local container image.
- `infra/terraform/`: Google Cloud and Cloudflare infrastructure.
- `.github/workflows/`: pull-request validation only. Production applies require an explicit human action.

## Working rules

1. Never commit secrets. This includes API or session tokens, passwords, private keys, Cloudflare Tunnel tokens, AWS access keys, Azure client secrets, GCP service-account keys, GitHub personal access tokens, webhook URLs, connection strings, registrar recovery codes, Terraform state, saved plans, and populated `.tfvars` or `.env` files.
2. Variables are not a security boundary. Keep non-secret configuration in Terraform or GitHub variables, but source sensitive values only from a secret manager, protected environment variable, or GitHub Actions/Environment secret. Never place a real secret in a variable default, example file, workflow YAML, command line, log, output, test fixture, issue, or pull request.
3. Prefer GitHub OIDC and short-lived cloud roles for GCP, AWS, and Azure instead of exporting long-lived cloud keys. Cloudflare credentials belong in the `CLOUDFLARE_API_TOKEN` environment variable and must be scoped to the minimum account, zone, and permissions.
4. Cloud account, subscription, tenant, project, zone, and role identifiers are not authentication secrets by themselves. Keep them in GitHub variables when public disclosure is acceptable, or in secrets when the owner wants the infrastructure metadata hidden.
5. Keep the origin closed to inbound Internet traffic. Do not add GCP ingress firewall rules or publish an origin IP in DNS.
6. Cloudflare DNS records for the site must remain proxied and must depend on the managed Tunnel. Remove DNS records before deleting their backing service.
7. Preserve the final catch-all `http_status:404` Tunnel ingress rule.
8. Treat changes to DNS, TLS, WAF rules, IAM, network egress, startup metadata, CI permissions, and Terraform state as security-sensitive.
9. Do not run `terraform apply` or `terraform destroy` from automation without a reviewed plan and an approved GitHub deployment environment.
10. If a secret is exposed, stop using it and revoke or rotate it immediately. Removing the file or rewriting Git history does not make the credential safe to reuse.
11. Pin every external GitHub Action to its full 40-character commit SHA and retain the release tag in a comment. Do not use mutable major-version tags such as `@v4`, branches, or `@main`.
12. Keep dependency update automation enabled so pinned Action SHAs, Terraform providers, and container base images receive reviewed update pull requests.

## Validation

Before proposing a change, run the checks that are available locally:

```sh
terraform -chdir=infra/terraform fmt -check -recursive
terraform -chdir=infra/terraform init -backend=false
terraform -chdir=infra/terraform validate
docker build -t cloudflare-portfolio:local site
```

If credentials are available, use `terraform plan` and review every replacement or deletion. Never include plan files in the repository because they can contain sensitive values.

Before pushing, inspect the staged diff and ensure GitHub secret scanning and push protection are enabled for the public repository. Do not bypass a secret-scanning warning for a real credential.

Verify workflow pins with:

```sh
rg -n "uses:" .github/workflows
```

Every external `uses:` value must end in a full commit SHA; a human-readable version belongs only in the trailing comment.

## Content changes

The site is deliberately buildless. Prefer semantic HTML, modern CSS, and small dependency-free JavaScript. Keep it responsive and keyboard accessible. Security headers are set in `site/nginx.conf`; update the Content Security Policy deliberately if new external assets are introduced.
