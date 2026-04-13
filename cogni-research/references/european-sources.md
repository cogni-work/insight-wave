> **Note**: This file is a human-readable reference for European markets beyond DACH.
> Research agents use `references/market-sources.json` for programmatic source lookups.
> Keep both in sync when updating sources. For DACH markets, see `dach-sources.md`.

# European Market Sources for Web Research

When `market` is set to a European country code (fr, it, pl, nl, es), section-researcher and deep-researcher include country-specific searches alongside standard English queries. This reference provides authoritative local-language sources per European market.

## Why Multi-Language European Search Matters

Each European market has institutional sources — national statistics offices, telecom regulators, industry associations, and business media — that publish primarily in their local language. Intent-based language routing applies the same principle as DACH: regulatory and association queries in local language, academic and global consulting queries in English.

---

## 1. France (market=fr)

### Research Institutes (Authority 5)

| Institute | Domain | Focus | Search Pattern |
|-----------|--------|-------|----------------|
| **INRIA** | inria.fr | Computer science, AI | `site:inria.fr {topic_fr} recherche {year}` |
| **CNRS** | cnrs.fr | National research center | `site:cnrs.fr {topic_fr} recherche {year}` |
| **CEA** | cea.fr | Energy, defense tech | `site:cea.fr {topic_fr} innovation {year}` |
| **CNES** | cnes.fr | Space agency | `site:cnes.fr {topic_fr} spatial satellite {year}` |

### Statistics & Government (Authority 5)

| Source | Domain | Focus | Search Pattern |
|--------|--------|-------|----------------|
| **INSEE** | insee.fr | National statistics | `site:insee.fr {topic_fr} statistiques {year}` |
| **Légifrance** | legifrance.gouv.fr | Legislation | `site:legifrance.gouv.fr {topic_fr} loi {year}` |
| **Ministère de l'Économie** | economie.gouv.fr | Economic policy | `site:economie.gouv.fr {topic_fr} numérique {year}` |
| **ARCEP** | arcep.fr | Telecom regulator | `site:arcep.fr {topic_fr} télécommunications {year}` |

### Associations (Authority 4)

| Association | Domain | Sector |
|-------------|--------|--------|
| **MEDEF** | medef.com | Employers federation |
| **Numeum** | numeum.fr | Digital industry (formerly Syntec Numérique) |
| **FFT** | fft.fr | Telecommunications federation |
| **BPI France** | bpifrance.fr | Innovation funding |

### Business Media (Authority 3)

| Source | Domain | Focus |
|--------|--------|-------|
| **Les Echos** | lesechos.fr | Business, economics |
| **La Tribune** | latribune.fr | Business, industry |
| **L'Usine Nouvelle** | usinenouvelle.com | Industry, manufacturing |
| **Journal du Net** | journaldunet.com | Digital business |

### Query Tips

- Compound nouns: "transformation numérique", "intelligence artificielle", "souveraineté numérique", "industrie du futur"
- Keep English: Cloud, IoT, AI, SaaS, DevOps, Machine Learning, LEO, 5G
- Geographic modifiers: "France", "français", "française"
- Regulatory: CNIL, AMF, ANSSI, ARCEP, Autorité de la concurrence

---

## 2. Italy (market=it)

### Research Institutes (Authority 5)

| Institute | Domain | Focus | Search Pattern |
|-----------|--------|-------|----------------|
| **CNR** | cnr.it | National research council | `site:cnr.it {topic_it} ricerca {year}` |
| **ASI** | asi.it | Italian Space Agency | `site:asi.it {topic_it} spazio satellite {year}` |
| **Politecnico di Milano** | polimi.it | Engineering, digital | `site:polimi.it {topic_it} ricerca innovazione {year}` |

### Statistics & Government (Authority 5)

| Source | Domain | Focus | Search Pattern |
|--------|--------|-------|----------------|
| **ISTAT** | istat.it | National statistics | `site:istat.it {topic_it} statistiche {year}` |
| **Gazzetta Ufficiale** | gazzettaufficiale.it | Official gazette | `site:gazzettaufficiale.it {topic_it} legge {year}` |
| **MISE** | mise.gov.it | Economic development | `site:mise.gov.it {topic_it} digitale innovazione {year}` |
| **AGCOM** | agcom.it | Telecom/media regulator | `site:agcom.it {topic_it} telecomunicazioni {year}` |
| **AGCM** | agcm.it | Competition authority | `site:agcm.it {topic_it} concorrenza {year}` |

### Associations (Authority 4)

| Association | Domain | Sector |
|-------------|--------|--------|
| **Confindustria Digitale** | confindustriadigitale.it | Digital industry federation |
| **ANIE** | anie.it | Electronics, IT, telecom |
| **Assintel** | assintel.it | ICT companies |

### Consulting (Authority 4)

| Source | Domain | Focus |
|--------|--------|-------|
| **The European House Ambrosetti** | ambrosetti.eu | Strategy consulting |

### Business Media (Authority 3)

| Source | Domain | Focus |
|--------|--------|-------|
| **Il Sole 24 Ore** | ilsole24ore.com | Business, economics |
| **CorCom** | corcom.it | Telecom, digital |
| **Wired Italia** | wired.it | Technology |

### Query Tips

- Compound nouns: "trasformazione digitale", "intelligenza artificiale", "cybersicurezza", "banda larga", "telecomunicazioni satellitari"
- Keep English: Cloud, IoT, AI, SaaS, LEO, 5G
- Character encoding: accented vowels (à, è, é, ì, ò, ù) — è = "is", e = "and"
- Geographic modifiers: "Italia", "italiano", "italiana"
- Regulatory: AGCOM, AGCM, Garante Privacy, CONSOB

---

## 3. Poland (market=pl)

### Research Institutes (Authority 5)

| Institute | Domain | Focus | Search Pattern |
|-----------|--------|-------|----------------|
| **PAN** | pan.pl | Polish Academy of Sciences | `site:pan.pl {topic_pl} badania {year}` |
| **NASK** | nask.pl | Cybersecurity research | `site:nask.pl {topic_pl} cyberbezpieczeństwo {year}` |
| **NCBiR** | ncbir.gov.pl | R&D center | `site:ncbir.gov.pl {topic_pl} innowacje {year}` |
| **POLSA** | polsa.gov.pl | Polish Space Agency | `site:polsa.gov.pl {topic_pl} kosmos satelity {year}` |

### Statistics & Government (Authority 5)

| Source | Domain | Focus | Search Pattern |
|--------|--------|-------|----------------|
| **GUS** | stat.gov.pl | Central Statistics Office | `site:stat.gov.pl {topic_pl} statystyki {year}` |
| **ISAP** | isap.sejm.gov.pl | Legislation database | `site:isap.sejm.gov.pl {topic_pl} ustawa {year}` |
| **UKE** | uke.gov.pl | Telecom regulator | `site:uke.gov.pl {topic_pl} telekomunikacja {year}` |
| **UOKiK** | uokik.gov.pl | Competition authority | `site:uokik.gov.pl {topic_pl} konkurencja {year}` |

### Associations (Authority 4)

| Association | Domain | Sector |
|-------------|--------|--------|
| **Lewiatan** | lewiatan.org | Employers confederation |
| **PIIT** | piit.org.pl | IT industry chamber |
| **KIGEiT** | kigeit.org.pl | Electronics & telecom chamber |

### Business Media (Authority 3)

| Source | Domain | Focus |
|--------|--------|-------|
| **Rzeczpospolita** | rp.pl | Business, law, economics |
| **Puls Biznesu** | pb.pl | Business daily |
| **Computerworld.pl** | computerworld.pl | IT, technology |

### Query Tips

- Compound nouns: "transformacja cyfrowa", "sztuczna inteligencja", "cyberbezpieczeństwo", "telekomunikacja satelitarna", "łączność satelitarna"
- Keep English: Cloud, IoT, AI, SaaS, LEO, 5G
- Character encoding: diacritics (ą, ć, ę, ł, ń, ó, ś, ź, ż) — never substitute with base Latin
- Geographic modifiers: "Polska", "polski", "polska"
- Regulatory: UKE, UOKiK, UODO, KNF
- Currency: PLN (not EUR)

---

## 4. Netherlands (market=nl)

### Research Institutes (Authority 5)

| Institute | Domain | Focus | Search Pattern |
|-----------|--------|-------|----------------|
| **TNO** | tno.nl | Applied research | `site:tno.nl {topic_nl} onderzoek {year}` |
| **NWO** | nwo.nl | Research council | `site:nwo.nl {topic_nl} onderzoek innovatie {year}` |
| **TU Delft** | tudelft.nl | Engineering, aerospace | `site:tudelft.nl {topic_nl} onderzoek {year}` |
| **NSO** | spaceoffice.nl | Netherlands Space Office | `site:spaceoffice.nl {topic_nl} ruimtevaart satellieten {year}` |

### Statistics & Government (Authority 5)

| Source | Domain | Focus | Search Pattern |
|--------|--------|-------|----------------|
| **CBS** | cbs.nl | Central statistics | `site:cbs.nl {topic_nl} statistieken {year}` |
| **Overheid.nl** | overheid.nl | Government portal | `site:overheid.nl {topic_nl} beleid {year}` |
| **ACM** | acm.nl | Competition/telecom regulator | `site:acm.nl {topic_nl} telecommunicatie mededinging {year}` |
| **RVO** | rvo.nl | Enterprise agency | `site:rvo.nl {topic_nl} innovatie subsidie {year}` |

### Associations (Authority 4)

| Association | Domain | Sector |
|-------------|--------|--------|
| **VNO-NCW** | vno-ncw.nl | Employers federation |
| **NLdigital** | nldigital.nl | Digital industry |
| **FME** | fme.nl | Technology federation |

### Consulting (Authority 4)

| Source | Domain | Focus |
|--------|--------|-------|
| **Berenschot** | berenschot.nl | Strategy consulting |

### Business Media (Authority 3)

| Source | Domain | Focus |
|--------|--------|-------|
| **Het Financieele Dagblad** | fd.nl | Financial newspaper |
| **Emerce** | emerce.nl | Digital business |
| **Computable** | computable.nl | IT industry |

### Query Tips

- Compound nouns: "digitale transformatie", "kunstmatige intelligentie", "cyberveiligheid", "satellietcommunicatie", "breedbandinfrastructuur"
- Keep English: Cloud, IoT, AI, SaaS, LEO, 5G (Dutch uses many English tech terms)
- Character encoding: standard Latin with occasional diacritics (ë, ï)
- Geographic modifiers: "Nederland", "Nederlands", "Nederlandse"
- Regulatory: ACM, Autoriteit Persoonsgegevens, AFM, DNB

---

## 5. Spain (market=es)

### Research Institutes (Authority 5)

| Institute | Domain | Focus | Search Pattern |
|-----------|--------|-------|----------------|
| **CSIC** | csic.es | National research council | `site:csic.es {topic_es} investigación {year}` |
| **CDTI** | cdti.es | Innovation center | `site:cdti.es {topic_es} innovación {year}` |
| **INTA** | inta.es | Aerospace research | `site:inta.es {topic_es} espacio satélites {year}` |

### Statistics & Government (Authority 5)

| Source | Domain | Focus | Search Pattern |
|--------|--------|-------|----------------|
| **INE** | ine.es | National statistics | `site:ine.es {topic_es} estadísticas {year}` |
| **BOE** | boe.es | Official gazette | `site:boe.es {topic_es} ley {year}` |
| **CNMC** | cnmc.es | Competition/telecom regulator | `site:cnmc.es {topic_es} telecomunicaciones competencia {year}` |
| **Red.es** | red.es | Digital connectivity | `site:red.es {topic_es} digitalización conectividad {year}` |

### Associations (Authority 4)

| Association | Domain | Sector |
|-------------|--------|--------|
| **CEOE** | ceoe.es | Employers federation |
| **Ametic** | ametic.es | Digital/telecom industry |
| **DigitalES** | digitales.es | Technology companies |

### Consulting (Authority 4)

| Source | Domain | Focus |
|--------|--------|-------|
| **Indra** | indracompany.com | Technology, defense, space |

### Business Media (Authority 3)

| Source | Domain | Focus |
|--------|--------|-------|
| **Expansión** | expansion.com | Business |
| **Cinco Días** | cincodias.elpais.com | Business, markets |
| **Computing.es** | computing.es | IT industry |

### Query Tips

- Compound nouns: "transformación digital", "inteligencia artificial", "ciberseguridad", "telecomunicaciones por satélite", "conectividad satelital"
- Keep English: Cloud, IoT, AI, SaaS, LEO, 5G
- Character encoding: accents (á, é, í, ó, ú), ñ, ü, inverted punctuation (¿, ¡)
- Geographic modifiers: "España", "español", "española"
- Regulatory: CNMC, AEPD, CNMV, Banco de España

---

## 6. EU-Wide Sources (market=eu)

These sources complement per-country sources for pan-European research.

| Source | Domain | Authority | Focus |
|--------|--------|-----------|-------|
| **EUR-Lex** | eur-lex.europa.eu | 5 | EU legislation database |
| **European Commission** | commission.europa.eu | 5 | Policy, strategy, digital single market |
| **Eurostat** | eurostat.ec.europa.eu | 5 | EU statistics |
| **EASA** | easa.europa.eu | 5 | Aviation/space regulation |
| **BEREC** | berec.europa.eu | 5 | EU telecom regulators body |
| **ESA** | esa.int | 5 | European Space Agency |
| **ENISA** | enisa.europa.eu | 5 | Cybersecurity agency |
| **EC Strategic Foresight** | commission.europa.eu | 5 | Annual foresight reports |
| **ESPAS** | espas.eu | 4 | EU horizon scanning |

---

## 7. Space & Satellite Sources (LEO-Relevant)

For satellite/LEO/space research, include these national space agencies and spectrum regulators:

| Country | Space Agency | Domain | Telecom Regulator | Domain |
|---------|-------------|--------|-------------------|--------|
| DE | DLR | dlr.de | BNetzA | bundesnetzagentur.de |
| FR | CNES | cnes.fr | ARCEP | arcep.fr |
| IT | ASI | asi.it | AGCOM | agcom.it |
| PL | POLSA | polsa.gov.pl | UKE | uke.gov.pl |
| NL | NSO | spaceoffice.nl | ACM | acm.nl |
| ES | INTA | inta.es | CNMC | cnmc.es |
| EU | ESA | esa.int | BEREC | berec.europa.eu |

---

## 8. Authority Scoring (All European Markets)

| Authority Level | Source Types | Score |
|-----------------|-------------|-------|
| **5** | National research councils, space agencies, statistics offices, EU institutions | 5 |
| **4** | Industry associations, chambers, regional consulting | 4 |
| **3** | Quality business media | 3 |
| **2** | Vendor content, promotional | 2 |

---

## 9. Bilingual Query Construction

The same intent-based language routing applies to all European markets:

| Query Type | Language | Example (Italian market) |
|------------|----------|--------------------------|
| Global reach | English | `"LEO satellite" broadband Europe market {year}` |
| Local perspective | Local | `"satellite LEO" banda larga Italia mercato {year}` |
| Site-specific | Local | `site:agcom.it telecomunicazioni satellitari {year}` |
| Regional in English | English | `"LEO satellite" Italy broadband regulation {year}` |

**General tips:**
- Use local-language terms for regulatory, association, and statistics queries
- Use English for academic, international consulting, and cross-border queries
- Include both local and English versions of the research topic
- Use `site:` operator for authority sources from `market-sources.json`
