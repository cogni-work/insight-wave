# Offering Entity Schema

Each discovered offering is captured with 11 fields:

| Field | Description | Example Values |
|-------|-------------|----------------|
| Name | Service/product name as marketed | "Managed SD-WAN Pro" |
| Description | 1-2 sentence summary | "End-to-end SD-WAN with 24/7 NOC support" |
| Domain | Source domain where offering was found | "t-systems.com" |
| Link | Direct URL to source page | `[Link](https://t-systems.com/sd-wan)` |
| USP | Unique selling proposition / differentiators | "Only provider with native 5G failover" |
| Provider Unit | Business unit offering this service | "T-Systems", "MMS" |
| Pricing Model | How the service is priced | subscription, usage-based, project-based |
| Delivery Model | Where service is delivered from | Onshore, nearshore, offshore, hybrid |
| Technology Partners | Key partnerships and certifications | "AWS Advanced Partner", "Microsoft Gold" |
| Industry Verticals | Target industries | Healthcare, Automotive, Public Sector |
| Service Horizon | Market maturity classification | Current, Emerging, Future |

## Service Horizons

| Horizon | Timeframe | Characteristics |
|---------|-----------|-----------------|
| Current | 0-1 years | Generally available, proven deployments |
| Emerging | 1-3 years | Pilot/beta, limited availability |
| Future | 3+ years | Announced, conceptual, R&D phase |

## Null-Safe Field Access

When processing offerings from log files, use null-safe access for optional fields (`partners`, `verticals`, `usp`, `pricing_model`, `delivery_model`):

```python
# CORRECT: Use 'or' to handle both missing AND null values
partners = (offer.get('partners') or '').replace('|', '\\|')[:60]
```

```bash
# Use // to provide default for null values
jq -r '.partners // ""'
```
