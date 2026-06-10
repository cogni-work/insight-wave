---
title: Business Case — SmartFactory Digitalisierung
engagement: smartfactory-dt
phase: deliver
---

# Business Case: Hybrid-Architektur mit Retrofit-first

## Investitionszusammenfassung

| Position | Betrag | Zeitraum |
|---|---|---|
| OPC-UA Aktivierung + Edge-Gateways (12 CNC + 3 Montagebänder) | €180K | Monate 1-6 |
| Cloud-MES Lizenz + Einrichtung | €220K | Monate 3-9 |
| Datenintegrations-Plattform (SAP-Schnittstelle) | €280K | Monate 6-12 |
| Mitarbeiterqualifizierung (Schichtleiter + Instandhaltung) | €120K | Monate 3-15 |
| Externe Begleitung (Siemens Partner + Change Management) | €350K | Monate 1-15 |
| Betriebsrat-Governance & Datenschutz-Framework | €80K | Monate 1-6 |
| Puffer (15% Risikoaufschlag) | €185K | — |
| **Gesamtinvestition** | **€1,415K** | **15 Monate** |

## Erwarteter Nutzen

| Nutzen | Jährlicher Wert | Basis |
|---|---|---|
| OEE-Verbesserung (10% auf 4 Linien) | €480K | Branchenbenchmark 8-15%, konservativer Ansatz bei 10%; berechnet auf Basis aktueller Produktionswerte (verifiziert) |
| Reduzierung ungeplanter Stillstände (Predictive Maintenance) | €320K | Aktuell 6,2% ungeplante Stillstandzeit; Ziel 3,5% basierend auf Vergleichsprojekten |
| Manuelle Datenerfassung eliminiert | €85K | 4 FTE-Äquivalente à 15h/Woche Datenerfassung; Umschichtung auf wertschöpfende Tätigkeiten |
| Qualitätskostenreduktion | €115K | Echtzeit-Prozessüberwachung ermöglicht Früherkennung; basierend auf aktuellem Ausschussanteil 2,8% |
| **Gesamt jährlicher Nutzen** | **€1,000K** | |

## Amortisation

- **Payback Period**: 17 Monate (ab Projektstart)
- **NPV (3 Jahre, 8% Diskontrate)**: €1,16M
- **ROI (3 Jahre)**: 112%

## Schlüsselannahmen

| Annahme | Status | Auswirkung bei Abweichung |
|---|---|---|
| 10% OEE-Verbesserung erreichbar | Geschätzt (Branchenbenchmark verifiziert: 8-15%) | ±€48K/Prozentpunkt jährlich |
| Betriebsrat-Kooperation bleibt bestehen | Verifiziert (Pilotprojekt-Zustimmung 2025) | Verzögerung 3-6 Monate bei Neuverhandlung |
| IT-Team kann OPC-UA mit externer Unterstützung aktivieren | Geschätzt (Siemens Partner bestätigt Machbarkeit) | +€40-60K für externes Fullservice |
| SAP S/4HANA Schnittstelle technisch realisierbar | Verifiziert (Standard-API vorhanden) | Alternativ: Middleware-Lösung (+€80K) |
| Qualifizierungsdauer 3-6 Monate für Schichtleiter | Geschätzt (keine Branchenstudie verfügbar) | Verzögert Nutzenrealisierung bei längerer Dauer |

## Sensitivitätsanalyse

| Szenario | NPV (3 Jahre) | ROI | Empfehlung |
|---|---|---|---|
| **Basis** (10% OEE, Plan-Timeline) | €1,16M | 112% | Go |
| **Konservativ** (8% OEE, +3 Monate Verzögerung) | €0,72M | 74% | Go |
| **Pessimistisch** (6% OEE, +6 Monate, +15% Kosten) | €0,21M | 18% | Conditional Go — Pilotphase zuerst |
| **Optimistisch** (12% OEE, Plan-Timeline) | €1,58M | 148% | Go |

## Risiken

| Risiko | Wahrscheinlichkeit | Auswirkung | Mitigation |
|---|---|---|---|
| Edge-Gateway Inkompatibilität mit Montagebändern | Mittel | €60-100K Zusatzkosten für Adapter | Pilotinstallation auf 1 Band in Phase 1 |
| Betriebsrat zieht Kooperation zurück | Niedrig | 3-6 Monate Verzögerung | Governance-Framework von Beginn an; transparente Datenverwendung |
| IT-Kapazitätsengpass (6-Personen-Team) | Hoch | Timeline-Risiko 2-3 Monate | Externe Unterstützung budgetiert; klare Priorisierung |
| OPC-UA Konfiguration komplexer als erwartet | Mittel | +€40K, +4 Wochen | Siemens Partner Ramp-up in Phase 1 |

## Empfehlung

**Conditional Go** — Projekt genehmigen mit folgenden Bedingungen:
1. Pilotphase (Linie 1 + Montageband 1) muss OEE-Verbesserung ≥6% nachweisen bevor Rollout auf alle Linien
2. Betriebsrat-Governance-Framework muss vor Beginn der Datenerfassung stehen
3. IT-Kapazitätsplanung muss extern abgesichert sein (Siemens Partner-Vertrag)

Begründung: Die Zahlen sind solide auch im pessimistischen Szenario (€0,21M NPV), aber die Organisation hat keine Erfahrung mit Digitalisierungsprojekten dieser Größenordnung. Ein erfolgreiches Pilotprojekt baut Kompetenz und Vertrauen auf, bevor die volle Investition fließt.
