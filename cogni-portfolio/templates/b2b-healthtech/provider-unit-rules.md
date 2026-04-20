# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Develops or sells health IT systems | Epic, Oracle Health, InterSystems | Core portfolio scope |
| Clinical platform division | Philips Health Technology, GE HealthCare IT | Dimensions 1-3 (Clinical, Engagement, Data) |
| Digital health subsidiary | Teladoc Health, Amwell | Dimension 2 (Patient Engagement) |
| Clinical informatics team | Health Catalyst analytics, Nuance DAX | Dimension 3 (Health Data & Interoperability) |
| Regulatory/compliance product group | Medidata, Veeva Vault | Dimension 5 (Regulatory & Compliance) |
| Life sciences technology division | IQVIA technology, Flatiron Health | Dimension 6 (Life Sciences Platform) |
| Professional services arm | Advisory Board, Deloitte Health IT | Dimension 7 (Advisory & Implementation) |
| Acquired product now integrated | Cerner (Oracle), Vocera (Stryker) | May have distinct capabilities across dimensions |
| Regional health IT entity | Localized editions, country-specific compliance modules | May have region-specific features or certifications |

## EXCLUDE only if ALL conditions are true

- Entity is purely medical device hardware manufacturing (and does not sell the software platform)
- Entity is a pharmaceutical sales team with no technology product
- Entity is a hospital or health system (the customer, not the vendor)
- Entity is a consumer wellness app with no B2B or provider-facing component

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize acquired products.** They often have unique capabilities (especially in Clinical Systems or Health Data & Interoperability) that would otherwise be missed.

**Separate product lines matter.** If a company operates multiple distinct health IT products (e.g., Oracle Health with Cerner Millennium, Oracle Health Clinical, Oracle Health EHR), each should be scanned as a potential product entity within the portfolio.
