---
title: Business Case — CostSmart IT Optimization
engagement: costsmart-it-opt
phase: deliver
---

# Business Case: Hybrid Optimization + Transformation

## Investment Summary

| Item | Amount | Period |
|---|---|---|
| AWS rightsizing and FinOps tooling | €120K | Months 1-3 |
| Cloud DR setup (DC2 replacement) | €280K | Months 3-6 |
| Self-service portal + automation | €180K | Months 4-8 |
| Staff retraining program (Tier 1 → Tier 2 skills) | €90K | Months 6-12 |
| BaFin compliance documentation | €60K | Months 1-12 |
| Project management and change advisory | €150K | Months 1-12 |
| Contingency (10%) | €88K | — |
| **Total investment** | **€968K** | **12 months** |

## Expected Annual Savings

| Savings Area | Annual Value | Basis |
|---|---|---|
| AWS rightsizing + FinOps governance | €775K | Verified: €650-900K range, midpoint used; adjusted for existing RI commitments |
| DC2 closure → cloud DR | €700K | Verified: DC2 costs €980K, cloud DR €280K, net €700K |
| Support model efficiency (self-service + automation) | €360K | 50% Tier 1 reduction × outsourced cost per ticket; sensitivity ±€140K |
| Reduced Tier 2/3 escalation (from 35% to 22%) | €165K | ServiceNow baseline × Gartner benchmark improvement |
| **Total annual savings** | **€2,000K** | |

**Note**: This reaches 63% of the €3.2M target. The remaining €1.2M requires vendor contract renegotiation (post-Q3 2027) and DC1 lease optimization (Q1 2027) — both are out of scope for the 12-month timeline but are flagged as Phase 2 opportunities.

## Key Financial Metrics

- **Payback period**: 6 months
- **NPV (3 years, 6% discount rate)**: €4.4M
- **ROI (3 years)**: 519%
- **Year 1 net benefit**: €1,032K (€2,000K savings - €968K investment)

## Sensitivity Analysis

| Scenario | Annual Savings | NPV (3 years) | Recommendation |
|---|---|---|---|
| **Base** (midpoint estimates) | €2,000K | €4.4M | Go |
| **Conservative** (low-end AWS + low self-service adoption) | €1,500K | €3.0M | Go |
| **Pessimistic** (low-end + DC2 migration delayed 3 months) | €1,200K | €2.2M | Go |
| **Optimistic** (high-end all estimates) | €2,500K | €5.8M | Go |

## Key Assumptions

| Assumption | Status | Impact if Wrong |
|---|---|---|
| AWS rightsizing: €650-900K range | Verified (adjusted down from original) | ±€125K annually |
| DC2 cloud DR: net €700K saving | Verified (adjusted down from €1.2M) | ±€100K if cloud costs increase |
| Self-service reduces Tier 1 by 50% | Estimated (Gartner range: 40-70%) | ±€140K annually |
| No vendor contract changes before Q3 2027 | Verified (contract clause review) | Upside if early negotiation possible |
| BaFin approves DC2→cloud migration | Assumed (§9 BAIT compliance planned) | 3-6 month delay if additional requirements |
| Works council approves support model change | **Not yet assessed** | Could delay or block retraining program |

## Risks

| Risk | Probability | Impact | Mitigation |
|---|---|---|---|
| BaFin additional requirements for cloud DR | Medium | €50-100K + 2-3 month delay | Pre-submission consultation planned |
| Self-service adoption lower than 50% | Medium | €70-140K less annual saving | Phased rollout with adoption incentives |
| AWS savings cannibalized by new workloads | Low | Erosion of savings over time | FinOps governance framework prevents unmanaged growth |
| IT staff resistance to retraining | Medium | Delays support model transition | Change management and early communication |

## Recommendation

**Conditional Go** — Proceed with Hybrid Optimization. The business case is robust even in the pessimistic scenario (€2.2M NPV). Conditions:
1. BaFin pre-submission consultation before DC2 migration
2. Works council alignment on support model changes before starting retraining
3. FinOps governance established before claiming AWS savings as realized
