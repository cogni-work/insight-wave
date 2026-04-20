# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Develops or sells marketing technology platforms | Adobe Experience Cloud, Salesforce Marketing Cloud, Braze | Core portfolio scope |
| Develops or sells advertising infrastructure | The Trade Desk, Google DV360, Amazon DSP | Dimension 4 (Advertising & Media) |
| Customer data or identity platform team | Segment, Tealium, LiveRamp | Dimension 1 (Customer Data & Identity) |
| Analytics product group for marketing | Adobe Analytics, Google Analytics 360, Amplitude | Dimension 5 (Analytics & Intelligence) |
| Professional services arm for platform implementation | Adobe Professional Services, Salesforce Marketing Cloud Services | Dimension 7 (Services & Enablement) |
| Creative technology team | Canva Enterprise, Adobe Creative Cloud for Teams | Dimension 3 (Content & Experience) |
| Acquired product now integrated | Marketo (Adobe), ExactTarget (Salesforce), Liftoff (Unity) | May have distinct capabilities across dimensions |
| Regional product entity | Localized editions, regional data centers | May have region-specific features or compliance |
| Privacy/consent technology unit | OneTrust, Cookiebot, Sourcepoint | Dimension 6 (Privacy & Compliance) |

## EXCLUDE only if ALL conditions are true

- Entity is a creative agency that uses MarTech but does not develop or sell it
- Entity is a media buying agency without proprietary technology
- Entity produces consumer-facing marketing campaigns (the output, not the platform)
- Entity is a pure CRM vendor whose offering is better classified under b2b-saas

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize acquired products.** They often have unique capabilities (especially in Customer Data & Identity or Analytics & Intelligence) that would otherwise be missed.

**Separate product lines matter.** If a company operates multiple distinct MarTech products (e.g., Adobe with Experience Platform, Analytics, Target, Campaign), each should be scanned as a potential product entity within the portfolio.
