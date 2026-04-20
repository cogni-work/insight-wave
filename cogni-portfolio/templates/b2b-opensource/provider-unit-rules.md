# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Maintains or commercializes the OSS project | Elastic (Elasticsearch), MongoDB Inc (MongoDB), HashiCorp (Terraform) | Core portfolio scope |
| Cloud platform team offering managed version | MongoDB Atlas, Confluent Cloud, Elastic Cloud | Dimension 3 (Cloud & Managed Services) |
| Developer relations / community team | DevRel, community engineering, developer advocacy | Dimension 4 (Developer Ecosystem) |
| Professional services arm | Consulting, training, implementation teams | Dimension 6 (Professional Services) |
| Subsidiary maintaining a specific OSS project | Acquired OSS projects with dedicated teams | Dimension 1 (Open Source Projects) |
| Security / compliance product group | Security hardening, FIPS, compliance features | Dimension 2 (Enterprise Platform) |
| Regional entity with localized offerings | EU-specific cloud regions, local support teams | May have region-specific compliance features |

## EXCLUDE only if ALL conditions are true

- Entity merely *uses* open-source internally but does not sell OSS-based products
- Entity is a pure proprietary SaaS that happens to use OSS components in its stack
- Entity is a community volunteer or foundation with no commercial arm

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize the OSS project itself.** Dimension 1 (Open Source Projects) captures the community health and project maturity that underpins all commercial value. Even though the OSS project is "free," it is the foundation of every IS statement.

**Forks and compatibility matter.** If the company has notable forks or compatibility claims (e.g., "wire-protocol compatible"), these should be captured in category 1.6. This is critical for competitive positioning.

**License changes are portfolio events.** If a company has changed its license model (e.g., Elastic moving from Apache to SSPL, HashiCorp from MPL to BSL), this should be captured in category 7.1 with the timeline and rationale, as it directly impacts IS/DOES/MEANS messaging.
