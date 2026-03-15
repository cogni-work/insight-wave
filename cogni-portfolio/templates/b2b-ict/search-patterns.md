# B2B ICT Search Patterns

Search queries for discovering ICT service offerings across the 8-dimension taxonomy. Used by the `scan` skill and `portfolio-web-researcher` agent.

## Phase 1: Company Discovery

Search for the target company and its affiliated entities:

```text
WebSearch: "{company name}" subsidiaries affiliates brands "ICT services" OR "IT services" OR "digital services"
WebSearch: "{company name}" group companies divisions business units
WebSearch: "{company name}" consulting advisory strategy "IT consulting"
WebSearch: "{company name}" "managed services" OR "onsite services" OR "field services" OR "IT outsourcing" subsidiary
```

**Extract:**

- Parent company name and primary web domain
- Subsidiary/affiliate companies with their web domains
- Business units that offer B2B ICT services
- Consulting/advisory subsidiaries (often have IT Strategy, Architecture services)
- On-site/field services subsidiaries (often have IT Support, IT Outsourcing services)
- Industry-vertical subsidiaries (e.g., healthcare IT, automotive IT)

## Phase 2: Provider Profile Discovery (Dimension 0)

Include the current year in Financial Scale and Workforce Capacity searches.

```text
WebSearch: site:{domain} "annual revenue" OR "turnover" OR "financial results" {current year}
WebSearch: site:{domain} "employees" OR "workforce" OR "team size" {current year}
WebSearch: site:{domain} "headquarters" OR "locations" OR "offices" OR "data centers"
WebSearch: site:{domain} "market share" OR "ranking" OR "analyst" OR "Gartner" OR "Forrester"
WebSearch: site:{domain} "ISO" OR "certifications" OR "accreditations" OR "compliance"
WebSearch: site:{domain} "partner" OR "AWS" OR "Azure" OR "GCP" OR "SAP" OR "Microsoft"
```

**Map findings to Dimension 0 categories:**

| Category | Search Focus |
|----------|--------------|
| 0.1 Financial Scale | Revenue, turnover, market cap, growth trends |
| 0.2 Workforce Capacity | Employee count, IT specialists, regional distribution |
| 0.3 Geographic Presence | HQ, delivery centers, service countries, data centers |
| 0.4 Market Position | Rankings, analyst ratings, reference clients |
| 0.5 Certifications & Accreditations | ISO certs, industry accreditations, compliance |
| 0.6 Partnership Ecosystem | Hyperscaler tiers, strategic alliances |

## Phase 3: Service Portfolio Discovery (Dimensions 1-7)

For each category, execute TWO site-scoped searches per domain (THREE when LANGUAGE=de):

1. **Marketing search (EN):** Standard category terms on primary domain
2. **Technical docs search:** Product names/synonyms on docs subdomain (if applicable)
3. **Marketing search (DE):** German category terms on primary domain (LANGUAGE=de only)

```text
# Pattern for each category:
Search 1 (Marketing EN): site:{{DOMAIN}} {standard_terms}
Search 2 (Tech Docs):    site:docs.{{DOMAIN}} OR site:help.{{DOMAIN}} {product_synonyms}
Search 3 (Marketing DE): site:{{DOMAIN}} {german_terms}  # only when LANGUAGE=de
```

Skip Search 2 if domain has no known docs subdomain. For domains like `t-systems.com`, also search `docs.otc.t-systems.com`.

---

### Dimension 1: Connectivity Services (7 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 1.1 | WAN Services | `site:{{DOMAIN}} "SD-WAN" OR "MPLS" OR "WAN" OR "network backbone"` | `site:{{DOMAIN}} "SD-WAN" OR "MPLS" OR "Weitverkehrsnetz" OR "Netzwerk"` | Cisco Viptela, VMware VeloCloud |
| 1.2 | SASE | `site:{{DOMAIN}} "SASE" OR "Secure Access Service Edge" OR "zero trust network"` | `site:{{DOMAIN}} "SASE" OR "Sicherer Netzwerkzugang" OR "Zero Trust"` | Zscaler, Palo Alto Prisma |
| 1.3 | Internet & Cloud Connect | `site:{{DOMAIN}} "dedicated internet" OR "cloud connect" OR "direct connect" OR "ExpressRoute"` | `site:{{DOMAIN}} "Cloud-Anbindung" OR "Standortvernetzung" OR "ExpressRoute"` | AWS Direct Connect, Azure ExpressRoute |
| 1.4 | 5G & IoT Connectivity | `site:{{DOMAIN}} "5G" OR "private 5G" OR "IoT connectivity" OR "M2M" OR "edge connectivity"` | `site:{{DOMAIN}} "5G" OR "Campusnetz" OR "IoT-Vernetzung" OR "Edge Computing"` | Campus Networks, Edge Computing |
| 1.5 | Voice Services | `site:{{DOMAIN}} "enterprise telephony" OR "SIP trunking" OR "UCaaS" OR "voice services"` | `site:{{DOMAIN}} "Telefonie" OR "SIP" OR "Sprachdienste" OR "Kommunikationslösung"` | Cisco Webex Calling, RingCentral |
| 1.6 | LAN/WLAN Services | `site:{{DOMAIN}} "LAN" OR "WLAN" OR "WiFi management" OR "campus network"` | `site:{{DOMAIN}} "LAN" OR "WLAN" OR "Netzwerkmanagement" OR "Campusnetz"` | Aruba, Cisco Meraki |
| 1.7 | Network-as-a-Service | `site:{{DOMAIN}} "Network-as-a-Service" OR "NaaS" OR "managed network"` | `site:{{DOMAIN}} "Netzwerk als Service" OR "NaaS" OR "Managed Network"` | - |

### Dimension 2: Security Services (10 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 2.1 | SOC/SIEM | `site:{{DOMAIN}} "SOC" OR "SIEM" OR "security operations" OR "MDR" OR "incident response"` | `site:{{DOMAIN}} "SOC" OR "SIEM" OR "Sicherheitsbetrieb" OR "Vorfallreaktion"` | XDR, Managed Detection and Response |
| 2.2 | IAM | `site:{{DOMAIN}} "identity management" OR "IAM" OR "PAM" OR "SSO" OR "MFA"` | `site:{{DOMAIN}} "Identitätsmanagement" OR "IAM" OR "Zugangsverwaltung" OR "MFA"` | Okta, CyberArk, Azure AD |
| 2.3 | Zero Trust | `site:{{DOMAIN}} "zero trust" OR "zero-trust" OR "ZTNA"` | `site:{{DOMAIN}} "Zero Trust" OR "ZTNA" OR "Vertrauensarchitektur"` | - |
| 2.4 | Cloud Security | `site:{{DOMAIN}} "cloud security" OR "CSPM" OR "CWPP" OR "cloud posture"` | `site:{{DOMAIN}} "Cloud-Sicherheit" OR "CSPM" OR "Cloud-Schutz"` | Wiz, Prisma Cloud |
| 2.5 | Endpoint Security | `site:{{DOMAIN}} "endpoint security" OR "EDR" OR "antimalware" OR "email security"` | `site:{{DOMAIN}} "Endpunktsicherheit" OR "EDR" OR "E-Mail-Sicherheit"` | CrowdStrike, Microsoft Defender |
| 2.6 | Network Security | `site:{{DOMAIN}} "firewall" OR "DDoS protection" OR "network security" OR "segmentation"` | `site:{{DOMAIN}} "Firewall" OR "DDoS-Schutz" OR "Netzwerksicherheit"` | Palo Alto, Fortinet, Check Point |
| 2.7 | Vulnerability Mgmt | `site:{{DOMAIN}} "vulnerability" OR "penetration testing" OR "security scanning" OR "patching"` | `site:{{DOMAIN}} "Schwachstellenmanagement" OR "Penetrationstest" OR "Sicherheitsprüfung"` | Qualys, Tenable, Rapid7 |
| 2.8 | Security Awareness | `site:{{DOMAIN}} "security awareness" OR "phishing simulation" OR "security training"` | `site:{{DOMAIN}} "Sicherheitsbewusstsein" OR "Phishing-Simulation" OR "Sicherheitsschulung"` | KnowBe4, Proofpoint |
| 2.9 | Compliance & GRC | `site:{{DOMAIN}} "compliance" OR "GRC" OR "audit" OR "regulatory"` | `site:{{DOMAIN}} "Compliance" OR "GRC" OR "Regulierung" OR "Datenschutz"` | ServiceNow GRC, RSA Archer |
| 2.10 | Data Protection | `site:{{DOMAIN}} "data protection" OR "DLP" OR "encryption" OR "privacy" OR "GDPR"` | `site:{{DOMAIN}} "Datenschutz" OR "DLP" OR "Verschlüsselung" OR "DSGVO"` | Varonis, Digital Guardian |

### Dimension 3: Digital Workplace Services (7 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 3.1 | Unified Communications | `site:{{DOMAIN}} "unified communications" OR "Teams" OR "Zoom" OR "collaboration" OR "video conferencing"` | `site:{{DOMAIN}} "Kommunikation" OR "Teams" OR "Zusammenarbeit" OR "Videokonferenz"` | Microsoft Teams, Webex |
| 3.2 | Modern Workplace / M365 | `site:{{DOMAIN}} "Microsoft 365" OR "M365" OR "Office 365" OR "modern workplace"` | `site:{{DOMAIN}} "Microsoft 365" OR "M365" OR "Moderner Arbeitsplatz"` | Copilot, SharePoint Online |
| 3.3 | Device Management | `site:{{DOMAIN}} "device management" OR "UEM" OR "MDM" OR "BYOD" OR "endpoint management"` | `site:{{DOMAIN}} "Geräteverwaltung" OR "UEM" OR "MDM" OR "Endgeräteverwaltung"` | Intune, VMware Workspace ONE |
| 3.4 | Virtual Desktop & DaaS | `site:{{DOMAIN}} "VDI" OR "DaaS" OR "virtual desktop" OR "remote desktop"` | `site:{{DOMAIN}} "VDI" OR "DaaS" OR "Virtueller Desktop" OR "Fernarbeitsplatz"` | Azure Virtual Desktop, Citrix |
| 3.5 | IT Support Services | `site:{{DOMAIN}} "service desk" OR "IT support" OR "field services" OR "helpdesk"` | `site:{{DOMAIN}} "Service Desk" OR "IT-Support" OR "Vor-Ort-Service" OR "Helpdesk"` | ServiceNow ITSM |
| 3.6 | Digital Employee Experience | `site:{{DOMAIN}} "employee experience" OR "DEX" OR "productivity analytics"` | `site:{{DOMAIN}} "Mitarbeitererfahrung" OR "DEX" OR "Produktivitätsanalyse"` | Nexthink, 1E |
| 3.7 | IT Asset Management | `site:{{DOMAIN}} "asset management" OR "ITAM" OR "hardware lifecycle" OR "print services"` | `site:{{DOMAIN}} "Asset Management" OR "ITAM" OR "Hardware-Lebenszyklus" OR "Druckservice"` | ServiceNow ITAM |

### Dimension 4: Cloud Services (8 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 4.1 | Managed Hyperscaler | `site:{{DOMAIN}} "managed AWS" OR "managed Azure" OR "managed GCP" OR "hyperscaler"` | `site:{{DOMAIN}} "Managed AWS" OR "Managed Azure" OR "Managed GCP" OR "Hyperscaler"` | AWS Premier Partner, Azure Expert MSP, GCP Partner |
| 4.2 | Multi-Cloud Management | `site:{{DOMAIN}} "multi-cloud" OR "FinOps" OR "cloud governance" OR "cloud management"` | `site:{{DOMAIN}} "Multi-Cloud" OR "FinOps" OR "Cloud-Governance" OR "Cloud-Management"` | CloudHealth, Flexera |
| 4.3 | Private Cloud | `site:{{DOMAIN}} "private cloud" OR "dedicated cloud" OR "on-premises cloud"` | `site:{{DOMAIN}} "Private Cloud" OR "Dedizierte Cloud" OR "eigene Cloud"` | VMware Cloud Foundation, OpenStack |
| 4.4 | Hybrid Cloud | `site:{{DOMAIN}} "hybrid cloud" OR "hybrid infrastructure"` | `site:{{DOMAIN}} "Hybrid Cloud" OR "Hybride Infrastruktur"` | Azure Arc, AWS Outposts |
| 4.5 | Cloud Migration | `site:{{DOMAIN}} "cloud migration" OR "cloud assessment" OR "move to cloud"` | `site:{{DOMAIN}} "Cloud-Migration" OR "Cloud-Bewertung" OR "Cloud-Umzug"` | AWS Migration Hub, Azure Migrate |
| 4.6 | Cloud-Native Platform | `site:{{DOMAIN}} "Kubernetes" OR "containers" OR "serverless" OR "cloud-native"` | `site:{{DOMAIN}} "Kubernetes" OR "Container" OR "Serverless" OR "Cloud-nativ"` | OpenShift, EKS, AKS, GKE |
| 4.7 | Sovereign Cloud | `site:{{DOMAIN}} "sovereign cloud" OR "data sovereignty" OR "government cloud"` | `site:{{DOMAIN}} "Souveräne Cloud" OR "Datensouveränität" OR "Behörden-Cloud" OR "DSGVO"` | Open Telekom Cloud, GDPR-compliant |
| 4.8 | Enterprise Platforms on Cloud | `site:{{DOMAIN}} "SAP on cloud" OR "Oracle on cloud" OR "enterprise workloads cloud"` | `site:{{DOMAIN}} "SAP in der Cloud" OR "Oracle Cloud" OR "Unternehmensanwendungen Cloud"` | **RISE with SAP, SAP S/4HANA Cloud, Oracle Cloud Infrastructure** |

### Dimension 5: Managed Infrastructure Services (7 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 5.1 | Data Center Services | `site:{{DOMAIN}} "data center" OR "colocation" OR "housing"` | `site:{{DOMAIN}} "Rechenzentrum" OR "Colocation" OR "Housing"` | - |
| 5.2 | Managed Compute & Storage | `site:{{DOMAIN}} "managed servers" OR "managed storage" OR "SAN" OR "NAS" OR "virtualization"` | `site:{{DOMAIN}} "Managed Server" OR "Speicher" OR "SAN" OR "Virtualisierung"` | vSphere, Elastic Cloud Server |
| 5.3 | Backup & DR | `site:{{DOMAIN}} "backup" OR "disaster recovery" OR "business continuity" OR "DR"` | `site:{{DOMAIN}} "Backup" OR "Disaster Recovery" OR "Geschäftskontinuität"` | Veeam, Commvault, Zerto |
| 5.4 | Infrastructure Monitoring | `site:{{DOMAIN}} "NOC" OR "monitoring" OR "infrastructure monitoring" OR "alerting"` | `site:{{DOMAIN}} "NOC" OR "Überwachung" OR "Infrastruktur-Monitoring"` | Datadog, Dynatrace, Splunk |
| 5.5 | IT Outsourcing | `site:{{DOMAIN}} "IT outsourcing" OR "ITO" OR "managed IT" OR "IT operations"` | `site:{{DOMAIN}} "IT-Outsourcing" OR "ITO" OR "IT-Betrieb" OR "Managed IT"` | - |
| 5.6 | Database Administration | `site:{{DOMAIN}} "DBA" OR "database administration" OR "database services"` | `site:{{DOMAIN}} "DBA" OR "Datenbankverwaltung" OR "Datenbankdienste"` | **RDS, Relational Database Service, DBaaS, Oracle RAC, SQL Server managed, PostgreSQL managed** |
| 5.7 | Infrastructure Automation | `site:{{DOMAIN}} "infrastructure automation" OR "IaC" OR "orchestration" OR "mainframe"` | `site:{{DOMAIN}} "Infrastruktur-Automatisierung" OR "IaC" OR "Orchestrierung" OR "Mainframe"` | Terraform, Ansible, z/OS |

### Dimension 6: Application Services (7 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 6.1 | Custom App Development | `site:{{DOMAIN}} "application development" OR "custom software" OR "software development"` | `site:{{DOMAIN}} "Anwendungsentwicklung" OR "Softwareentwicklung" OR "Individualentwicklung"` | Agile, Scrum, .NET, Java |
| 6.2 | App Modernization | `site:{{DOMAIN}} "application modernization" OR "legacy migration" OR "re-platforming"` | `site:{{DOMAIN}} "Anwendungsmodernisierung" OR "Legacy-Migration" OR "Re-Plattformierung"` | Strangler pattern, Microservices |
| 6.3 | Enterprise Platforms | `site:{{DOMAIN}} "SAP" OR "Salesforce" OR "ServiceNow" OR "application management"` | `site:{{DOMAIN}} "SAP" OR "Salesforce" OR "ServiceNow" OR "Anwendungsmanagement"` | **SAP S/4HANA, SAP ECC, RISE with SAP, Salesforce Industries** |
| 6.4 | System Integration & API | `site:{{DOMAIN}} "system integration" OR "API management" OR "enterprise integration"` | `site:{{DOMAIN}} "Systemintegration" OR "API-Management" OR "Unternehmensintegration"` | MuleSoft, Apigee, Kong |
| 6.5 | Low-Code/No-Code | `site:{{DOMAIN}} "low-code" OR "no-code" OR "Power Platform" OR "citizen development"` | `site:{{DOMAIN}} "Low-Code" OR "No-Code" OR "Power Platform" OR "Fachanwenderentwicklung"` | OutSystems, Mendix |
| 6.6 | AI, Data & Analytics | `site:{{DOMAIN}} "AI" OR "artificial intelligence" OR "machine learning" OR "analytics" OR "data platform" OR "generative AI"` | `site:{{DOMAIN}} "KI" OR "Künstliche Intelligenz" OR "maschinelles Lernen" OR "Datenplattform" OR "generative KI"` | Azure OpenAI, Databricks, Snowflake |
| 6.7 | DevOps & Platform Eng | `site:{{DOMAIN}} "DevOps" OR "CI/CD" OR "platform engineering" OR "GitOps"` | `site:{{DOMAIN}} "DevOps" OR "CI/CD" OR "Plattform-Engineering" OR "GitOps"` | GitHub, GitLab, ArgoCD |

### Dimension 7: Consulting Services (5 categories)

| ID | Category | Marketing Query (EN) | DE Marketing Query | Product Synonyms |
|----|----------|----------------------|--------------------|------------------|
| 7.1 | IT Strategy & Architecture | `site:{{DOMAIN}} "IT strategy" OR "enterprise architecture" OR "technology roadmap"` | `site:{{DOMAIN}} "IT-Strategie" OR "Unternehmensarchitektur" OR "Technologie-Roadmap"` | TOGAF, EAM, Technology Assessment |
| 7.2 | Digital Transformation | `site:{{DOMAIN}} "digital transformation" OR "digitalization" OR "change management"` | `site:{{DOMAIN}} "Digitale Transformation" OR "Digitalisierung" OR "Change Management"` | Design Thinking, Process Mining |
| 7.3 | Business & Industry Consulting | `site:{{DOMAIN}} "business consulting" OR "industry consulting" OR "ESG" OR "sustainability"` | `site:{{DOMAIN}} "Unternehmensberatung" OR "Branchenberatung" OR "Nachhaltigkeit" OR "ESG"` | Industry 4.0, Smart Factory |
| 7.4 | Program & Project Mgmt | `site:{{DOMAIN}} "program management" OR "project management" OR "PMO"` | `site:{{DOMAIN}} "Programmmanagement" OR "Projektmanagement" OR "PMO"` | PRINCE2, PMP, SAFe |
| 7.5 | Vendor & Contract Mgmt | `site:{{DOMAIN}} "vendor management" OR "contract management" OR "procurement" OR "sourcing"` | `site:{{DOMAIN}} "Lieferantenmanagement" OR "Vertragsmanagement" OR "Beschaffung"` | - |

---

## Technical Documentation Search Enhancement

For categories with high-value technical documentation (especially 4.8, 5.6, 6.3), execute an additional search targeting documentation subdomains:

```text
# Example for Category 5.6 Database Administration
Search 1: site:{domain} "DBA" OR "database administration"
Search 2: site:docs.{domain} OR site:docs.otc.{domain} "RDS" OR "Relational Database Service" OR "database management" OR "PostgreSQL" OR "MySQL managed"
```

**Priority categories for tech docs search:** 4.8, 5.6, 6.3, 4.6, 5.7
