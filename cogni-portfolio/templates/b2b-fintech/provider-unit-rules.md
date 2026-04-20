# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Develops or sells fintech platform products | Stripe, Adyen, Finastra, FIS | Core portfolio scope |
| Regulated entity holding financial licenses | EMI/PI subsidiaries, licensed banks, broker-dealers | Dimension 0 (Certifications), Dim 1-4 capabilities |
| Compliance or RegTech subsidiary | KYC/AML units, regulatory reporting arms | Dimension 3 (Risk & Compliance) |
| Regional payment entity with local licenses | Local acquiring licenses, domestic payment rails | Dimension 1 (Payment Services) |
| Insurance technology arm | InsurTech subsidiaries, underwriting platforms | Dimension 5 (Insurance Technology) |
| Professional services / consulting division | Implementation teams, regulatory advisory | Dimension 7 (Advisory & Implementation) |
| Acquired product now integrated | Acquired payment gateways, banking platforms, data providers | May have distinct capabilities across dimensions |
| Banking-as-a-Service / embedded finance unit | BaaS platforms, embedded finance APIs | Dimension 2 (Banking) or 6 (Data & Intelligence) |
| Partner/channel organization | Reseller programs, ISV partnerships, SI channel | Dimension 0 (Partnership Ecosystem) |

## EXCLUDE only if ALL conditions are true

- Entity is a consumer banking arm with no B2B platform offering
- Entity is a retail investment app with no white-label or API capability
- Entity is an internal treasury operation with no external product
- Entity provides no technology capabilities or regulated services to B2B clients

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize acquired products.** They often have unique capabilities (especially in Payment Services, Banking, or Risk & Compliance) that would otherwise be missed.

**Separate product lines matter.** If a company operates multiple distinct fintech products (e.g., FIS with payment processing, core banking, and capital markets), each should be scanned as a potential product entity within the portfolio.

**Regulated entities matter.** If a subsidiary holds its own financial license (EMI, PI, banking, broker-dealer), it likely has distinct capabilities and should be included even if it shares branding with the parent.
