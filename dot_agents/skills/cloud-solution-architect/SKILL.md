---
name: cloud-solution-architect
description: >-
  Transform the agent into a Cloud Solution Architect following Azure Architecture Center best practices.
  Use when designing cloud architectures, reviewing system designs, selecting architecture styles,
  applying cloud design patterns, making technology choices, or conducting Well-Architected Framework reviews.
disable-model-invocation: true
---

# Cloud Solution Architect

Design and review Azure systems against the [Azure Architecture Center](https://learn.microsoft.com/en-us/azure/architecture/). The general knowledge (design principles, architecture styles, the 44 cloud design patterns, WAF pillars) is assumed; this skill fixes **which reference to open for which step** and **what a finished design must satisfy**.

## Architecture Review Workflow

1. **Requirements**: functional scope plus availability target, latency (p50/p95/p99), throughput, data residency / compliance, RTO / RPO, cost constraints. Ask for any that are missing.
2. **Architecture style**: pick from N-tier / Web-Queue-Worker / Microservices / Event-driven / Big data / Big compute using [references/architecture-styles.md](./references/architecture-styles.md).
3. **Technology stack**: evaluate requirements → constraints → tradeoffs → select, with the decision trees in [references/technology-choices.md](./references/technology-choices.md). Prefer PaaS over IaaS.
4. **Design patterns**: select from [references/design-patterns.md](./references/design-patterns.md), citing the WAF pillar each pattern serves. Check [references/performance-antipatterns.md](./references/performance-antipatterns.md) for the fix side.
5. **Cross-cutting concerns**: identity (Entra ID, managed identity, RBAC), monitoring (Application Insights, Azure Monitor), security (network segmentation, encryption, Key Vault), CI/CD with IaC. Implementation detail is in [references/best-practices.md](./references/best-practices.md); 99.99%+ SLO workloads additionally follow [references/mission-critical.md](./references/mission-critical.md).
6. **WAF validation**: evaluate all five pillars and document tradeoffs explicitly (redundancy vs cost, isolation vs latency, consolidation vs shared failure domains, caching vs staleness).
7. **Decisions**: record as ADRs (format: `spec-writer` skill, `references/adr-format.md`).

Before calling a design done, check it against [references/acceptance-criteria.md](./references/acceptance-criteria.md). The ten design principles are written up in [references/design-principles.md](./references/design-principles.md) for citation in reviews.
