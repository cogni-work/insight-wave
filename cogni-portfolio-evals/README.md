# cogni-portfolio-evals

Eval harness for cogni-portfolio skills. Regression and generalization testing with fixture portfolios, structural assertions, and stakeholder reviewer agents.

> **Note:** This is an internal test suite, not a marketplace plugin. It is not listed in marketplace.json and is not installable via `/plugin install`.

## Why this exists

cogni-portfolio has 16 skills generating structured JSON and markdown across products, features, propositions, markets, competitors, customers, solutions, and packages. Changes to one skill can break output quality in others. This eval harness catches regressions before they ship and validates that skills generalize across different company contexts.

## What it does

1. **Define** eval cases as JSON with prompts, fixture paths, and assertion types (structural, agent, review-loop, persona, behavioral, qualitative)
2. **Run** evals against fixture portfolios — each eval invokes a cogni-portfolio skill and checks the output
3. **Review** results with 13 stakeholder reviewer agents (CMO, CSO, CDO, procurement, product management, market analyst perspectives)
4. **Iterate** — analyze failures, fix source skills in cogni-portfolio, re-run until quality gates pass

## Eval targets

| Fixture | Company | Purpose |
|---------|---------|---------|
| `t-systems/` | T-Systems | Primary regression target — full portfolio with features, markets, propositions, solutions |
| `t-systems-solutions/` | T-Systems | Solution-focused variant with 3 propositions and solutions |
| `t-systems-de/` | T-Systems | German-language variant (cold-start with portfolio.json only) |
| `bechtle/` | Bechtle | Generalization target — cold-start scenario (portfolio.json only) |

## Skills covered

| Skill | Eval count | What's tested |
|-------|-----------|---------------|
| features | 4 | Review, generate, improve, repair |
| propositions | 4 | Batch generate, review, single generate, dual-reviewer review-loop |
| customers | 5 | Profile generation, named customer research, review assessor, convergence loop |
| compete | 4 | Competitor analysis, trap questions, CSO+Analyst review-loop |
| portfolio-scan | 3 | Full scan (EN), mid-market scan, German-language scan |
| markets | 3 | Discovery, direct creation, cold-start |
| products | 3 | Define, cold-start, strategic review |
| packages | 3 | Generate tiers, review existing, batch readiness |

30 eval cases total across 9 skills.

## Reviewer agents

13 stakeholder personas providing domain-specific quality assessment:

- **T-Systems CMO** — internal GTM readiness
- **T-Systems CSO** — sales actionability
- **Mainova CDO** — external buyer perspective (energy utility)
- **Energieversorger CDO** — external buyer perspective (large utility)
- **Customers CSO** — sales perspective on customer profiles
- **Customers Market Expert** — market accuracy of customer profiles
- **Market Industry Analyst** — market and industry analysis quality
- **Packages Procurement Expert** — procurement viability of package tiers
- **Packages Sales Manager** — sales perspective on packages
- **Packages Reviewer** — general package quality
- **Products PM** — product management perspective
- **Products Procurement** — procurement perspective on products
- **Products Reviewer** — general product quality

## Results

Latest eval run (2026-03-18): 100% structural pass rate across all skills. CMO score 4.2, CDO score 4.0. 10 root causes identified and fixed in source skill files over 3 iterations. See [RESULTS.md](RESULTS.md) for details.

## Architecture

```
cogni-portfolio-evals/
├── evals/
│   └── evals.json                30 eval case definitions
├── fixtures/                     4 target company portfolios
│   ├── t-systems/
│   ├── t-systems-solutions/
│   ├── t-systems-de/
│   └── bechtle/
├── agents/                       13 stakeholder reviewer agents
├── scripts/                      Eval runner utilities
├── skill-snapshots/              Frozen skill versions per iteration
├── iteration-0/ .. iteration-7/  Iteration results and analysis
└── RESULTS.md                    Latest results summary
```

## License

[AGPL-3.0](LICENSE)
