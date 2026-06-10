---
title: Action Roadmap — SmartFactory Digitalisierung
engagement: smartfactory-dt
phase: deliver
---

# Action Roadmap

## Phasenübersicht

| Phase | Zeitraum | Fokus | Budget |
|---|---|---|---|
| 1: Pilot & Fundament | Monate 1-5 | OPC-UA Aktivierung Linie 1, Edge-Gateway Montageband 1, Governance-Framework | €380K |
| 2: Datenplattform | Monate 4-9 | Cloud-MES Anbindung, SAP-Schnittstelle, Dashboards | €420K |
| 3: Rollout & Qualifizierung | Monate 8-13 | Alle Linien anbinden, Schichtleiter-Qualifizierung, Predictive Maintenance | €430K |
| 4: Optimierung | Monate 12-15 | KPI-Tuning, Qualitätsüberwachung, Skalierungsvorbereitung | €185K (inkl. Puffer) |

## Phase 1: Pilot & Fundament (Monate 1-5)

**Ziel**: Proof of Concept auf Linie 1 + Montageband 1; Governance-Framework steht

### Arbeitspakete
- OPC-UA Aktivierung auf 3 CNC-Maschinen (Linie 1) — 2 PT/Maschine, Siemens Partner
- Edge-Gateway Installation Montageband 1 — Kompatibilitätstest + Datenerfassung
- Betriebsrat-Governance-Framework: Datenverwendungsrichtlinie, Transparenz-Dashboard
- IT-Team Onboarding: OPC-UA Grundschulung (Siemens Partner, 5 Tage)

### Ressourcen
- 2 IT-Mitarbeitende (50% Kapazität, nach SAP-Stabilisierung verfügbar)
- 1 Siemens Partner Consultant (3 Monate, 4 Tage/Woche)
- 1 Change Management Berater (Betriebsrat-Governance, 2 Tage/Woche)

### Decision Gate → Phase 2
- [ ] OPC-UA Daten von Linie 1 fließen in zentrales Dashboard
- [ ] Edge-Gateway Montageband 1 liefert verwertbare Daten
- [ ] Betriebsrat hat Governance-Framework abgenommen
- [ ] OEE-Baseline für Linie 1 etabliert (Messung läuft ≥4 Wochen)

## Phase 2: Datenplattform (Monate 4-9)

**Ziel**: Cloud-MES Anbindung, SAP-Integration, erste operative Dashboards

### Arbeitspakete
- Cloud-MES Lizenzierung und Konfiguration (basierend auf Pilot-Erkenntnissen)
- SAP S/4HANA Schnittstelle: Auftrags- und Qualitätsdaten bidirektional
- Operative Dashboards: OEE, Stillstandanalyse, Qualitätskennzahlen
- OPC-UA Rollout auf Linie 2 (parallel zu MES-Aufbau)

### Ressourcen
- 3 IT-Mitarbeitende (70% Kapazität — SAP-Schnittstelle erfordert SAP-Expertise)
- Cloud-MES Implementierungspartner (5 Monate)
- 1 Datenintegrations-Spezialist (extern, 4 Monate)

### Decision Gate → Phase 3
- [ ] Cloud-MES operativ mit Linie 1 + 2 Daten
- [ ] SAP-Schnittstelle funktionsfähig (Auftragsdaten bidirektional)
- [ ] Schichtleiter Linie 1 nutzen Dashboard aktiv (>80% der Schichten)
- [ ] OEE-Verbesserung Linie 1 ≥6% gegenüber Baseline

## Phase 3: Rollout & Qualifizierung (Monate 8-13)

**Ziel**: Alle Linien angebunden, Predictive Maintenance Pilot, flächendeckende Qualifizierung

### Arbeitspakete
- OPC-UA Aktivierung Linien 3 + 4 (IT-Team eigenständig, Partner begleitend)
- Edge-Gateway Montagebänder 2 + 3
- Predictive Maintenance Algorithmen (basierend auf 6+ Monate Maschinendaten)
- Schichtleiter-Qualifizierung: Datenkompetenz-Programm (alle 4 Linien, 3-6 Monate)
- Instandhaltungsteam-Schulung: Predictive Maintenance Interpretation

### Ressourcen
- 4 IT-Mitarbeitende (80% Kapazität — Organisation hat gelernt)
- Siemens Partner (reduziert auf 2 Tage/Woche, Coaching-Modus)
- Externer Trainer für Qualifizierungsprogramm

### Decision Gate → Phase 4
- [ ] Alle 12 CNC-Maschinen + 3 Montagebänder senden Daten
- [ ] Predictive Maintenance Pilot auf Linie 1 zeigt Reduktion ungeplanter Stillstände
- [ ] ≥70% der Schichtleiter nutzen Dashboards aktiv
- [ ] Qualitätsdaten fließen in Echtzeit (Ausschuss-Früherkennung aktiv)

## Phase 4: Optimierung (Monate 12-15)

**Ziel**: KPI-Optimierung, Qualitätsüberwachung, Vorbereitung weitere Standorte

### Arbeitspakete
- OEE-Optimierung basierend auf gesammelten Daten (Feintuning Predictive Maintenance)
- Echtzeit-Qualitätsüberwachung: automatische Ausschuss-Warnungen
- Dokumentation und Playbook für potenzielle Standort-Replikation
- Evaluierung: Ist-vs-Soll Vergleich gegen Business Case

### Decision Gate → Abschluss / Standort-Replikation
- [ ] OEE-Verbesserung ≥8% über alle Linien (vs. 10% Ziel)
- [ ] Ungeplante Stillstände ≤4,0% (vs. 3,5% Ziel)
- [ ] Business Case NPV on-track (±20% der Prognose)
- [ ] Standort-Replikation Playbook erstellt

## Abhängigkeiten

| Abhängigkeit | Auswirkung bei Verzögerung | Mitigation |
|---|---|---|
| Betriebsrat-Governance (Phase 1) → alle nachfolgenden Datenerfassungen | Blockiert Phase 2 Rollout | Governance als erstes Arbeitspaket; wöchentliche BR-Abstimmung |
| SAP-Team Verfügbarkeit (Phase 2) | SAP-Schnittstelle verzögert MES-Nutzen | SAP-Arbeiten auf ruhigere Periode (nach Quartalsabschluss) legen |
| Pilot-Ergebnisse Linie 1 (Phase 1) → Rollout-Entscheidung (Phase 3) | Kein Go für Rollout ohne Pilot-Evidenz | Pilot beginnt sofort; 4 Wochen Datenerhebung einplanen |
| Siemens Partner Verfügbarkeit | Verzögerung OPC-UA Aktivierung | LOI vor Projektstart; Alternative: Beckhoff Partner als Backup |
