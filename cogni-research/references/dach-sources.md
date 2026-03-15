# DACH-Specific Sources for Research

When project language is `de`, the batch-creator and findings-creator should leverage DACH-specific sources for deeper regional intelligence. This reference provides domain lists organized by search profile type for integration with the profile-based search system.

---

## Localized Profile: DACH Domains

When language=de and the `localized` search profile is selected, use these allowed_domains to target DACH-specific sources.

### General Business & Economics

```json
["handelsblatt.com", "faz.net", "wiwo.de", "manager-magazin.de", "dihk.de", "bdi.eu", "rolandberger.com"]
```

### Technology & Digital

```json
["bitkom.org", "t3n.de", "deutsche-startups.de", "digitalswitzerland.com", "bvdw.org"]
```

### Manufacturing & Engineering

```json
["vdma.org", "zvei.org", "staufen.ag", "fraunhofer.de"]
```

### Automotive

```json
["vda.de", "vdma.org", "zvei.org"]
```

### Energy & Utilities

```json
["bdew.de", "dena.de"]
```

### Healthcare & Pharma

```json
["bvmed.de", "vfa.de", "vci.de"]
```

### Financial Services

```json
["gdv.de", "bdb.de", "bitkom.org"]
```

### Austrian Sources

```json
["wko.at", "iv.at", "ffg.at"]
```

### Swiss Sources

```json
["swissmem.ch", "economiesuisse.ch", "digitalswitzerland.com", "innosuisse.ch"]
```

---

## Academic Profile: DACH Research

When language=de and the `academic` profile is selected, include:

```json
["fraunhofer.de", "publica.fraunhofer.de", "mpg.de"]
```

These complement the standard academic sources (arxiv.org, ieee.org, etc.) with German applied research that English-only academic searches miss.

---

## Industry Profile: DACH Trade Press

When language=de and the `industry` profile is selected, include these alongside standard industry sources:

```json
["handelsblatt.com", "wiwo.de", "manager-magazin.de", "faz.net"]
```

---

## Authority Boost Rules

When scoring finding quality in findings-creator, boost recognized DACH domains:

| Domain Pattern | Authority Boost | Rationale |
|----------------|----------------|-----------|
| `*.fraunhofer.de` | +0.10 | Europe's largest applied research org |
| `*.mpg.de` | +0.10 | Top European basic research |
| `vdma.org`, `bitkom.org`, `vda.de`, `zvei.org` | +0.08 | Major German industry associations |
| `bdew.de`, `bdi.eu`, `dihk.de` | +0.08 | Federal-level industry bodies |
| `handelsblatt.com`, `faz.net` | +0.05 | Quality business journalism |
| `wko.at`, `iv.at`, `swissmem.ch` | +0.08 | Austrian/Swiss industry bodies |
| `eur-lex.europa.eu` | +0.10 | Official EU law |

Apply these boosts on top of the standard 4-dimension quality scoring (Relevance 35%, Completeness 25%, Reliability 15%, Freshness 15%, Evidentiary Value 10%). The boost adds to the composite score, capped at 1.00.

---

## Bilingual Query Strategy for batch-creator

When generating search configs for German-language projects:

1. **Always include both EN and DE queries** — English for global reach, German for DACH depth
2. **For each `general` profile query**, create a German equivalent using industry-specific German terms
3. **For each `localized` profile**, use DACH allowed_domains from the lists above
4. **Match association to topic**: Use the sector mapping below to pick the right site-specific search

### Sector → Association Mapping

| Topic Sector | Primary Association | Domain |
|-------------|---------------------|--------|
| IT/Digital | BITKOM | bitkom.org |
| Manufacturing | VDMA | vdma.org |
| Automotive | VDA | vda.de |
| Electrical/Electronics | ZVEI | zvei.org |
| Energy | BDEW | bdew.de |
| Retail | HDE | hde.de |
| Insurance | GDV | gdv.de |
| Chemicals/Pharma | VCI | vci.de |
| Banking | BdB | bdb.de |
| Healthcare | BVMed | bvmed.de |
| Logistics | BGL/DSLV | bgl-ev.de |
| General Industry | BDI | bdi.eu |

### German Query Tips

- Use compound nouns: "Digitalisierungsstrategie", "Energiewende", "Fachkräftemangel"
- Include "Deutschland Österreich Schweiz" or "DACH" for regional scope
- German-language queries surface Mittelstand perspectives that English misses
- Keep English technical terms when they're standard (e.g., "Cloud Computing", "IoT", "AI")
