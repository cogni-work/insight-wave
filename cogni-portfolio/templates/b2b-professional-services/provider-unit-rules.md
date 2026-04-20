# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Practice area delivering advisory or project work to B2B clients | McKinsey Strategy, Deloitte Consulting | Core portfolio scope |
| Competence center with client-facing mandates | Arcadis Resilience, AECOM Program Management | Dimensions 1-6 (service capabilities) |
| Named industry group delivering sector-specific advisory | McKinsey Healthcare, Deloitte Financial Services | Dimension 4 (Industry Practices) |
| Regional office with specialized practices | Arcadis Netherlands (water), AECOM Middle East (infrastructure) | May have region-specific capabilities |
| Joint venture with industry-specific mandates | Co-delivery partnerships, consortium arrangements | May have distinct service capabilities |
| Acquired firm now integrated into practice | Monitor (Deloitte), Booz (PwC Strategy&) | May have unique capabilities across dimensions |
| Professional services arm of a broader organization | Deloitte Consulting (within Deloitte), EY-Parthenon (within EY) | Distinct advisory capabilities |

## EXCLUDE only if ALL conditions are true

- Entity is an internal shared services function (HR, finance, IT) that does not deliver client-facing work
- Entity is a purely academic or research arm with no commercial engagements
- Entity is a real estate or facilities management division with no advisory mandate

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize acquired firms.** They often have unique capabilities (especially in Strategy & Transformation or Industry Practices) that would otherwise be missed.

**Separate practice lines matter.** If a firm operates multiple distinct practice areas (e.g., Deloitte with Consulting, Risk Advisory, Financial Advisory, Tax), each should be scanned as a potential provider unit within the portfolio.
