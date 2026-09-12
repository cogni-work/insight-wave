---
arc_id: jtbd-portfolio
display_name: JTBD Portfolio
display_name_de: JTBD-Portfolio
contract: 2
---

# JTBD Portfolio

## Intent

**Governing question:** What jobs does the buyer hire for, what stands in the way of each, which solution does each job, and where does the buyer start?

**Rhetorical job:** Introduce a solution portfolio to buyers who think in outcomes, not features. The arc maps the buyer's world into functional jobs, quantifies the friction on each, maps solutions one-to-one to jobs, and closes on a single low-commitment entry point with a handoff to deal-specific selling.

**Not for:** deal-specific sales pitches for a named customer (cogni-sales `/why-change`), feature-centric product documentation, research-driven narratives with no portfolio data (`corporate-visions` or a research arc), or proving a customer's observed transformation (`customer-transformation`).

## Selection

**Best for:** portfolio introductions, capability overviews, pre-sales positioning, B2B portfolio narratives, the `home` and `persona` scopes of cogni-portfolio's customer narrative.

**Signals:** portfolio entities are the source (propositions with IS/DOES/MEANS, customers with pain points, markets, solutions, competitors); the reader is a buyer evaluating what a company solves; content type `jtbd`; keywords such as "jobs-to-be-done", "functional job", "portfolio map", "capability overview", "pre-sales positioning".

**Anti-signals:** a single named prospect with deal-specific research; research syntheses with no propositions; a company self-description with no solution set.

**Fallback priority:** never a fallback. Selected only when portfolio entities or an explicit `jtbd` content type are present.

## Headings

Byte-exact section headers by output language. Renderers, the copywriter and the validation script all match these strings; never paraphrase, re-case or re-punctuate them.

| # | EN | DE | FR | IT | PL | NL | ES |
|---|----|----|----|----|----|----|----|
| 1 | Job Landscape: Functional Jobs | Job-Landschaft: Funktionale Aufgaben | Panorama des tâches : tâches fonctionnelles | Panorama dei job: job funzionali | Krajobraz zadań: zadania funkcjonalne | Takenlandschap: functionele taken | Panorama de tareas: tareas funcionales |
| 2 | Friction Map: Obstacles and Cost of Inaction | Reibungskarte: Hindernisse und Handlungsdruck | Carte des frictions : obstacles et coût de l'inaction | Mappa degli attriti: ostacoli e costo dell'inazione | Mapa tarć: przeszkody i koszt bezczynności | Frictiekaart: obstakels en kosten van nietsdoen | Mapa de fricciones: obstáculos y coste de la inacción |
| 3 | Portfolio Map: Solutions by Job | Portfolio-Zuordnung: Lösungen je Aufgabe | Cartographie du portefeuille : solutions par tâche | Mappa del portfolio: soluzioni per job | Mapa portfolio: rozwiązania według zadań | Portfoliokaart: oplossingen per taak | Mapa de portfolio: soluciones por tarea |
| 4 | Invitation: Next Step | Einladung: Nächster Schritt | Invitation : prochaine étape | Invito: prossimo passo | Zaproszenie: następny krok | Uitnodiging: volgende stap | Invitación: siguiente paso |

The narrative skill generates EN and DE. The five further columns are the substitution set the copywriter uses in arc-mode translation; they are carried here because this contract is the one authority for the arc's headings.

## Composition

Section lengths are proportions of `--target-length` (default 1,675 words). Word ranges for a target `T` are `[T × 0.85, T × 1.15]` multiplied by each proportion. Proportions sum to 100%.

| Segment | Proportion |
|---------|-----------:|
| Job Landscape | 27% |
| Friction Map | 23% |
| Portfolio Map | 30% |
| Invitation | 20% |

**Executive TL;DR emphasis:** jobs → friction → portfolio → invitation. The narrative opens with the TL;DR defined in `validation.md`; the industry observation that reframes buyers from products to jobs belongs in its first sentence as the conclusion, not as a context setter.

**Transitions:**

1. Job Landscape → Friction Map: "Each job carries friction that compounds into measurable cost."
2. Friction Map → Portfolio Map: "Your portfolio maps 1:1 to these jobs."
3. Portfolio Map → Invitation: "Start with [lowest-commitment option]."

**Closing pattern:** an explicit cogni-sales handoff — "When you have a named prospect, `/why-change` builds the deal-specific case."

## Elements

### 1. Job Landscape

**Purpose:** map the buyer's world into three or four functional jobs they hire solutions for, phrased as verb phrases in the buyer's language.

**Evidence sought:** customer pain points (each implies a job), proposition DOES statements (each reveals the job a solution does), the market description for industry vocabulary. Read them from the loaded portfolio entities or the `--content-map`.

**Argument move:** open with a contrast that reframes from products to jobs ("Your portfolio has 6 products. Your buyer has 4 jobs."), then present each job as a named verb-phrase entry with one or two sentences of context and a quantified scope where the evidence allows, and close by handing over to friction.

**Techniques:** [Contrast Structure](techniques-overview.md#6-contrast-structure), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** every job is a verb phrase ("Reduce unplanned downtime below 2%"), never a product category ("Predictive Maintenance"); three or four jobs, no more; each job appears in at least one proposition's DOES domain; job wording passes a buyer-language test — words the buyer would use, not internal product names.

**Failure modes:** product categories as jobs; seven jobs covering every product; abstract jobs with no measurable outcome; seller perspective ("leverage our platform").

### 2. Friction Map

**Purpose:** for each job, name the current obstacle and quantify the cost of leaving it unsolved — a compressed Why Change, per job rather than global.

**Evidence sought:** pain-point detail, competitor weaknesses (what current approaches fail to deliver), proposition evidence arrays for cost figures.

**Argument move:** per job — the primary obstacle, the quantified cost of its persistence, and any external pressure that makes it urgent; then stack the per-job costs into a compound figure across the landscape.

**Techniques:** [Forcing Functions](techniques-overview.md#5-forcing-functions), [Compound Impact](techniques-overview.md#8-compound-impact-calculation), [Number Plays](techniques-overview.md#4-number-plays-6-techniques) (before/after).

**Hard rules:** every job from element 1 has a friction entry that names the job by its verb phrase; every friction carries a quantified cost of inaction with a citation; no friction blames the buyer.

**Failure modes:** global friction with no per-job linkage ("organizations face transformation challenges"); qualitative cost ("significant disruption"); an obstacle stack with no numbers.

### 3. Portfolio Map

**Purpose:** map solutions one-to-one to the jobs, each positioned as the thing the buyer hires for that job.

**Evidence sought:** proposition IS/DOES/MEANS statements, solution implementation detail, feature descriptions for the IS layer.

**Argument move:** open with the 1:1 mapping statement, then for each job — introduced as "For the job of [verb phrase]…" — the matching solution in IS-DOES-MEANS order: IS a coherent definition, DOES the outcome for the buyer in You-Phrasing with numbers, MEANS the barrier competitors cannot cross.

**Techniques:** [IS-DOES-MEANS](techniques-overview.md#3-is-does-means-power-positions), [You-Phrasing](techniques-overview.md#7-you-phrasing), [Number Plays](techniques-overview.md#4-number-plays-6-techniques).

**Hard rules:** strict 1:1 — count(jobs) equals count(solutions mapped), verified before writing; a solution with no job is flagged as orphaned in a note, a job with no solution is named as a gap; no feature lists — a list of capabilities collapses into one IS sentence; every DOES layer is second person and quantified.

**Failure modes:** bullet-point feature dumps; a solution with no job anchor; six solutions for four jobs; third-person DOES.

### 4. Invitation

**Purpose:** one clear, low-commitment entry point, and an explicit handoff to cogni-sales for deal-specific tailoring.

**Evidence sought:** solution entry tiers (proof of value, pilot, assessment), package starter tiers where packages exist.

**Argument move:** connect to the map (the portfolio is mapped, now act), present the single entry point with its investment and deliverable — preferring the highest-friction job first, or proof before portfolio — and close on the handoff.

**Techniques:** [You-Phrasing](techniques-overview.md#7-you-phrasing).

**Hard rules:** exactly one entry point, never a menu or a pricing ladder; investment and deliverable stated; the handoff names `/why-change` for a named customer; the invitation starts a conversation, it does not close a deal.

**Failure modes:** "choose from Basic, Professional or Enterprise"; "contact sales for more information"; a feature dump in the invitation.

## Validation

Arc-specific assertions, checked after the universal gates in `validation.md`:

- Every job in Job Landscape is a verb phrase in buyer language; there are three or four of them.
- Count of jobs equals count of solutions in Portfolio Map; orphans and gaps are named explicitly.
- Portfolio Map uses IS-DOES-MEANS per solution and carries no feature list.
- Every friction entry names its job and carries a cited cost of inaction.
- Invitation presents one entry point and names `/why-change` for deal-specific tailoring.
- The chain holds: the TL;DR's conclusion is the one the four elements earn; the jobs are the ones the frictions block; the frictions are the ones the portfolio resolves; the invitation follows the map.

## See Also

- `arc-registry.md` — arc selection: detection algorithm, per-arc declarative blocks, shortlist format
- `techniques-overview.md` — the eight techniques and their application matrix
- `validation.md` — the universal gates every narrative must clear
