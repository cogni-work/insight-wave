# Provider Unit Classification Rules

A **provider unit** is any organizational unit of the target company that will be scanned independently (subsidiary, practice area, acquired product, regional entity, brand). This file defines which to include. *Not to be confused with `delivery_blueprint` on products — that is the commercial implementation pattern, not an organizational unit.*

## INCLUDE as provider unit if ANY of these criteria are met

| Criterion | Examples | Why Include |
|-----------|----------|-------------|
| Develops, sells, or implements industrial automation hardware/software | Siemens Digital Industries, Rockwell Automation, ABB Robotics | Core portfolio scope |
| OT platform or Industrial IoT subsidiary | Siemens MindSphere, PTC ThingWorx, AVEVA | Dimension 4 (Industrial IoT & Data) |
| Factory/plant engineering division | Siemens Process Industries & Drives, ABB Energy Industries | Dimension 7 (Engineering & Advisory) |
| Service organization for installed base | Schneider Electric Services, Honeywell Lifecycle Solutions | Dimension 6 (Lifecycle & Service) |
| OT cybersecurity division or acquisition | Claroty (Rockwell), Nozomi Networks partnership | Dimension 5 (OT Cybersecurity) |
| Acquired product now integrated | AVEVA (Schneider), Mendix (Siemens), FLIR (Teledyne) | May have distinct capabilities across dimensions |
| Regional product entity | Localized editions, regional service centers | May have region-specific capabilities or compliance |
| Digital twin / simulation division | Siemens Xcelerator, Dassault DELMIA | Dimension 3 (Digital Twin & Simulation) |

## EXCLUDE only if ALL conditions are true

- Entity is a consumer appliance division with no industrial technology offerings
- Entity is a building technology division (unless serving industrial buildings or facilities)
- Entity is a pure financial services arm with no technology capabilities
- Entity is an automotive components business (unless selling the manufacturing technology itself)

**Principle: When in doubt, INCLUDE.** Phase 3 research will naturally return no offerings if the entity isn't relevant.

**Never deprioritize acquired products.** They often have unique capabilities (especially in IoT, cybersecurity, or simulation) that would otherwise be missed.

**Separate product lines matter.** If a company operates multiple distinct industrial technology platforms (e.g., Siemens with SIMATIC, SINUMERIK, SINAMICS), each should be scanned as a potential product entity within the portfolio.
