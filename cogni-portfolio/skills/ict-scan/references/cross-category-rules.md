# Cross-Category Assignment Rules

Some offerings legitimately span multiple taxonomy categories. After aggregating offerings from all domains, analyze each offering for multi-category fit.

## Detection Rules

```text
FOR each offering in all_offerings:

  # Rule 1: Cloud infrastructure + Application services → dual category
  IF offering.category == "6.3" (Enterprise Platform Services)
     AND (offering.description CONTAINS "cloud infrastructure"
          OR offering.delivery_model == "cloud"
          OR offering.name CONTAINS "RISE with SAP")
  THEN also_assign_to("4.8")  # Enterprise Platforms on Cloud

  # Rule 2: Sovereign cloud + Data protection → dual category
  IF offering.category == "4.7" (Sovereign Cloud)
     AND offering.description CONTAINS "privacy" OR "data protection" OR "GDPR"
  THEN also_assign_to("2.10")  # Data Protection & Privacy

  # Rule 3: Managed security + IT outsourcing → dual category
  IF offering.category == "2.1" (SOC/SIEM)
     AND offering.description CONTAINS "outsourcing" OR "operations"
  THEN also_assign_to("5.5")  # IT Outsourcing

  # Rule 4: Cloud-native + DevOps → dual category
  IF offering.category == "4.6" (Cloud-Native Platform)
     AND offering.description CONTAINS "CI/CD" OR "DevOps" OR "GitOps"
  THEN also_assign_to("6.7")  # DevOps & Platform Engineering

  # Rule 5: Hyperscaler partnership → consider 4.1
  IF offering.partners CONTAINS "AWS" OR "Azure" OR "GCP"
     AND offering.category NOT IN ["4.1", "4.2"]
  THEN consider_for("4.1")  # Flag for review
```

## Dual-Category Assignment Patterns

| Pattern | Primary Category | Secondary Category | Trigger |
|---------|-----------------|-------------------|---------|
| RISE with SAP | 6.3 | 4.8 | Name contains "RISE with SAP" or "SAP RISE" |
| SAP on Cloud | 4.8 | 6.3 | SAP + cloud infrastructure mentioned |
| Sovereign Cloud | 4.7 | 2.10 | Data sovereignty + privacy/protection |
| Managed SOC + ITO | 2.1 | 5.5 | SOC/SIEM + IT operations outsourcing |
| Cloud-Native + DevOps | 4.6 | 6.7 | Kubernetes + CI/CD/DevOps |

When duplicating to a secondary category: copy all 11 fields, update `category`, add `cross_category_source` to track origin.
