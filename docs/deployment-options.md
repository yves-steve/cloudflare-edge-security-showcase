# Deployment options and use cases

This project deliberately presents two approaches instead of claiming that one architecture is universally best. The right answer depends on whether the goal is to operate a static website efficiently or to demonstrate public-cloud security engineering.

> *The objective is architectural judgment, not collecting cloud logos like achievement badges.*

## Option A: Cloudflare Workers Static Assets — the website just needs to be a website

### What it is

Cloudflare stores and serves the HTML, CSS, JavaScript, and other static files from its global network. A custom domain points directly to the Worker project, so Cloudflare is both the public edge and the application origin.

Cloudflare recommends Workers Static Assets for new static projects. Pages remains supported, but new features and optimizations are focused on Workers.

### Best use cases

- Personal portfolio or résumé.
- Product landing page or company brochure site.
- Project documentation.
- Event or campaign site with no server-side state.
- Single-page application that calls an external API.
- Static site that may later add a small Worker-based contact form or API.

### Benefits

- Static asset requests are free and unlimited.
- Asset storage has no additional charge.
- No VM, operating system, NAT gateway, container runtime, or web server needs patching. Your weekend remains suspiciously uninterrupted.
- There is no separate origin IP for an attacker to discover or bypass.
- Custom domains receive Cloudflare-managed DNS records and certificates.
- Zone WAF, DDoS, redirect, transform, and bot controls can still apply.
- Git-based previews and small deployments are straightforward.

### Limitations and tradeoffs

- It demonstrates Cloudflare well, but demonstrates less knowledge of AWS, Azure, or GCP networking.
- Code that requires a traditional server, arbitrary background process, or unsupported runtime needs another platform.
- Moving away from Cloudflare requires changing deployment configuration and possibly platform-specific functions.
- Dynamic Worker requests have Workers plan limits even though ordinary static asset requests are free.
- Browser security headers must be expressed through Cloudflare static-asset configuration rather than relying only on Nginx.

### Example scenario

> A security engineer wants a public portfolio containing an introduction, project screenshots, and links to GitHub. The content changes a few times per month and has no database. Workers Static Assets is the appropriate live platform because a VM would add cost and maintenance without adding user value.

## Option B: GCP Compute Engine plus Cloudflare Tunnel — the lab-coat option

### What it is

Terraform creates a GCP VPC, subnet, deny-ingress firewall rule, optional Cloud NAT, and hardened Compute Engine VM. Nginx serves the static files locally. `cloudflared` initiates an outbound Tunnel connection, and Cloudflare publishes the site without opening an inbound port on the VM.

### Best use cases

- A portfolio project intended to demonstrate cloud networking and Terraform.
- An existing containerized or server-based application.
- A workload that requires OS packages, local processes, or a general-purpose runtime.
- A training lab for private-origin connectivity and Cloudflare Tunnel.
- A future application with backend logic that does not fit Workers.

### Benefits

- Demonstrates VPC, subnet, firewall, NAT, VM, bootstrapping, and IAM concepts.
- Demonstrates an outbound-only connector and private-origin pattern.
- Provides control over the runtime, container, web server, and OS-level configuration.
- The same pattern can be adapted to AWS EC2, Azure Virtual Machines, Kubernetes, or an on-premises server.
- Separates the edge provider from the compute provider.

### Limitations and tradeoffs

- Cloud NAT, public IPv4, storage, logging, and traffic may create costs even when the VM qualifies for a Free Tier allowance. Cloud billing is an enthusiastic teacher.
- The VM, base image, containers, and connector require patching and monitoring.
- Terraform state contains a sensitive Tunnel token and needs an encrypted remote backend.
- A single VM and Tunnel connector are an availability limitation.
- The architecture is unnecessarily complex for a small static-only production site.

### Example scenario

> A candidate wants to demonstrate that they can deploy a private cloud workload, prevent direct Internet ingress, connect it to an edge provider, and manage the dependency order in Terraform. The GCP plus Tunnel track is valuable as a lab, even though it is not the cheapest way to host the portfolio itself.

## Side-by-side responsibility model

| Responsibility | Workers Static Assets | GCP plus Tunnel |
| --- | --- | --- |
| Static file storage | Cloudflare | GCP VM disk/container |
| Web server patching | Cloudflare-managed | Project owner |
| Public origin IP | None | None in secure mode; external egress IP in low-cost mode |
| TLS certificate | Cloudflare-managed | Cloudflare-managed at the browser edge |
| Inbound firewall | No origin firewall required | Explicit deny-all ingress |
| Connector | Not required | `cloudflared` on the VM |
| Terraform state secret | No Tunnel token required | Tunnel token present |
| Typical idle infrastructure cost | $0 excluding the domain | Low but not necessarily $0 |
| Public-cloud skills demonstrated | Limited | Strong |
| Operational effort | Low | Moderate |

## Recommended portfolio strategy

1. Run the public portfolio continuously on Workers Static Assets.
2. Keep the GCP architecture fully documented and validated in Terraform.
3. Deploy the GCP lab only for demonstrations, testing, screenshots, or interviews.
4. Destroy the GCP lab afterward to control cost, while retaining its code and architecture evidence in Git.
5. If the site later needs a small dynamic feature, add a Worker route first. Move to the GCP origin only when the runtime requirements justify it.

This approach demonstrates cost awareness and architectural judgment: the simplest platform runs the real workload, while the more complex platform exists for a concrete learning and demonstration purpose.

In other words: production stays boring, and the lab gets interesting on demand. That is a feature, not a lack of ambition.

## References

- [Workers Static Assets best-practice recommendation](https://developers.cloudflare.com/workers/best-practices/workers-best-practices/)
- [Workers Static Assets billing and limitations](https://developers.cloudflare.com/workers/static-assets/billing-and-limitations/)
- [Workers platform limits](https://developers.cloudflare.com/workers/platform/limits/)
- [Workers custom domains](https://developers.cloudflare.com/workers/configuration/routing/custom-domains/)
- [Cloudflare Tunnel](https://developers.cloudflare.com/tunnel/)
- [Google Cloud NAT pricing](https://cloud.google.com/nat/pricing)
- [Google Cloud Free Program](https://docs.cloud.google.com/free/docs/free-cloud-features)
