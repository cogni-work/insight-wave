# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Develops or sells the SaaS platform | HubSpot, ServiceNow, Workday | Core portfolio scope |
| Vertical solution team | Veeva (life sciences), nCino (banking) | Dimension 7 (Industry Solutions) |
| Professional services arm | Salesforce Professional Services, ServiceNow Expert Services | Dimension 5 (Customer Success & Support) |
| Developer platform / ecosystem team | Salesforce AppExchange, Shopify App Store | Dimension 3 (Integration & Ecosystem) |
| Acquired product now integrated | Slack (Salesforce), Qualtrics (SAP) | May have distinct capabilities across dimensions |
| Regional product entity | Localized editions, regional data centers | May have region-specific features or compliance |
| Partner/channel organization | Reseller programs, MSP offerings | Dimension 6 (Pricing & Packaging) |

## EXCLUDE only if ALL conditions are true

- Entity is purely a reseller with no product development or differentiation
- Entity has no SaaS product or platform offering
- Entity provides no technology capabilities to B2B customers

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize acquired products.** They often have unique capabilities (especially in Data & Analytics or Industry Solutions) that would otherwise be missed.

**Separate product lines matter.** If a company operates multiple distinct SaaS products (e.g., Atlassian with Jira, Confluence, Bitbucket), each should be scanned as a potential product entity within the portfolio.
