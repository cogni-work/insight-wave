# Decisions: Near-Term Choices Under Uncertainty Patterns

## Element Purpose

Specify near-term decisions that position organization to respond effectively as uncertainty resolves—what to decide now vs. later, and what triggers change timing.

**Word Target:** 250-350 words

## Source Content Mapping

Extract from:
1. **Strategic Recommendations** (primary source)
   - Immediate action items
   - Decision sequencing
   - Information requirements

2. **Strategies** (from previous element)
   - Robust strategy implementation
   - Hedge activation triggers
   - Flexibility preservation

3. **Trends**
   - Decision timing indicators
   - Signal monitoring approaches
   - Trigger events

4. **Dimension Syntheses**
   - Implementation considerations
   - Risk factors
   - Timeline constraints

## Structure Components

### Decision Specification (250-350 words)

**What to extract:**
- Decide-now items (reversible, low-cost, enabling)
- Decide-later items (irreversible, expensive, wait-for-information)
- Information triggers (what signals indicate decision timing)
- Decision sequencing (what must happen first)

**Questions to answer:**
- What decisions must happen immediately?
- What decisions should wait for more information?
- What information would change decisions?
- What's the cost of deciding too early vs. too late?

**Example:**
```markdown
**Decide now (0-6 months):**

**Deploy governance infrastructure:** Valuable across all scenarios, reversible if priorities shift, enables compliance readiness<sup>[1]</sup>. Decision: ModelOp vs. Fiddler vs. Arthur AI. Timeline: 3-month vendor selection, 3-month deployment.

**Establish multi-jurisdiction presence:** Low-cost footprint in EU + US + Asia through partnerships or small teams ($200-400K)<sup>[2]</sup>. Creates optionality if regulatory fragmentation unfolds. Reversible through team redeployment if convergence occurs.

**Begin proprietary data collection:** No-regret move with immediate value and cross-scenario benefits<sup>[3]</sup>. Decision: Which data sources (customer interactions, operational telemetry, domain expertise). Timeline: 6-month infrastructure build.

---

**Decide later (wait for signals):**

**Major model infrastructure investment ($2M+):** Wait for commoditization vs. concentration clarity<sup>[4]</sup>. Premature commitment creates stranded assets if scenario doesn't unfold as expected.

**Trigger:** If open-source models reach <5% performance gap with proprietary (currently 15-20%), signals commoditization—invest in open-source infrastructure. If gap widens to >25%, signals concentration—invest in platform partnerships<sup>[5]</sup>.

**Jurisdiction commitment (choose primary regulatory home):** Wait for regulatory framework clarity<sup>[6]</sup>. Premature jurisdiction selection creates lock-in if regulations diverge unexpectedly.

**Trigger:** If EU-US regulatory divergence exceeds 40% requirement overlap (currently 70%), signals balkanization—commit to single jurisdiction. If convergence increases to >85%, maintain multi-jurisdiction optionality<sup>[7]</sup>.

---

**Information to monitor:**

**Monthly:** Open-source vs. proprietary performance gaps, regulatory announcement tracking, enterprise AI spending trends<sup>[8]</sup>

**Quarterly:** Scenario signal strength assessment, strategic portfolio rebalancing, decision trigger review<sup>[9]</sup>

**Annually:** Major strategic decisions (platform partnerships, acquisition targets, market positioning)<sup>[10]</sup>

---

**Decision sequencing:**

**Phase 1 (Month 1-3):** Deploy governance (enables all scenarios), establish data collection (no-regret), initiate multi-jurisdiction exploration<sup>[11]</sup>

**Phase 2 (Month 4-9):** Monitor signals, build modular infrastructure, develop partnerships with 2-3 vendors (preserves flexibility)<sup>[12]</sup>

**Phase 3 (Month 10-18):** Make major commitments based on signal clarity—model infrastructure, jurisdiction selection, platform partnerships<sup>[13]</sup>

Sequencing ensures reversible decisions first, irreversible decisions only after uncertainty reduction<sup>[14]</sup>.
```

## Transformation Patterns

### Pattern 1: Reversibility-Based Decision Timing

**When to use:** Distinguishing what to decide now vs. later based on reversibility

**Structure:**
```markdown
**High reversibility (decide now):**
- [Decision 1]: [Why reversible, low cost to change]<sup>[citation]</sup>
- [Decision 2]: [Why reversible, low cost to change]<sup>[citation]</sup>

**Low reversibility (decide later):**
- [Decision 3]: [Why irreversible, wait for information]<sup>[citation]</sup>
- [Decision 4]: [Why irreversible, wait for information]<sup>[citation]</sup>

**Reversibility premium:** [Cost of maintaining optionality vs. committing]<sup>[citation]</sup>
```

**Example:**
```markdown
**High reversibility (decide now):**
- **Vendor partnerships:** Establish relationships with AWS, Hugging Face, Mistral without exclusive commitments<sup>[1]</sup>. Reversible through contract terms (30-90 day exit clauses), minimal switching costs ($20-40K).
- **Team skill development:** Train engineers on multiple AI platforms<sup>[2]</sup>. Reversible through project reallocation, cross-training valuable regardless of platform choice.

**Low reversibility (decide later):**
- **Custom model development ($2-5M):** Proprietary model investment creates 18-24 month sunk cost<sup>[3]</sup>. Irreversible if commoditization makes models free. Wait for performance gap clarity.
- **Jurisdiction-specific compliance architecture:** Rebuilding for different jurisdiction costs 60-80% of original build<sup>[4]</sup>. Irreversible once deployed. Wait for regulatory convergence/divergence clarity.

**Reversibility premium:** Maintaining flexibility (partnerships vs. single vendor, modular vs. custom) costs 15-25% more upfront but enables $400K-1.2M in avoided switching costs<sup>[5]</sup>. Premium worthwhile given scenario uncertainty.
```

---

### Pattern 2: Information-Triggered Decision Framework

**When to use:** Decisions depend on specific information becoming available

**Structure:**
```markdown
**Decision: [What to decide]**

**Current information gap:** [What's unknown]<sup>[citation]</sup>

**Information trigger:** [Specific signal that enables decision]<sup>[citation]</sup>

**Decision logic:**
- **If [trigger condition A]:** Then [action A]<sup>[citation]</sup>
- **If [trigger condition B]:** Then [action B]<sup>[citation]</sup>
- **If [trigger condition C]:** Then [action C]<sup>[citation]</sup>

**Monitoring approach:** [How to track triggers]<sup>[citation]</sup>

**Cost of waiting:** [What's lost by not deciding immediately]<sup>[citation]</sup>
```

**Example:**
```markdown
**Decision: Model infrastructure investment ($2-5M in proprietary vs. open-source)**

**Current information gap:** Unclear whether open-source will reach proprietary parity or gap will persist<sup>[1]</sup>. Current gap: 15-20% on key benchmarks, narrowing 4-6% quarterly.

**Information trigger:** Open-source vs. proprietary performance gap trajectory over next 9-12 months<sup>[2]</sup>

**Decision logic:**
- **If gap narrows to <5%:** Invest in open-source infrastructure (commoditization signals strong)<sup>[3]</sup>. Deploy Llama, Mistral, self-hosted deployment, $1-2M infrastructure.
- **If gap remains 15-20% or widens:** Invest in proprietary partnerships (concentration signals strong)<sup>[4]</sup>. Commit to OpenAI/Anthropic platforms, $2-3M multi-year contracts.
- **If gap volatile (±10% quarterly swings):** Maintain flexibility through multi-vendor approach<sup>[5]</sup>. Continue current strategy, defer major commitment 6-12 months.

**Monitoring approach:** Monthly benchmark tracking (MMLU, HumanEval, domain-specific tests), quarterly performance gap analysis, vendor roadmap reviews<sup>[6]</sup>

**Cost of waiting:** Delaying infrastructure investment 9-12 months means missing early adopter advantages (estimated 15-20% market share opportunity)<sup>[7]</sup>. But premature commitment creates $1-2M stranded asset risk. Expected value favors waiting given uncertainty.
```

---

### Pattern 3: Sequential Decision Roadmap

**When to use:** Decisions must happen in specific order with dependencies

**Structure:**
```markdown
**Decision 1 (Month [timeframe]): [What to decide]**
- **Rationale:** [Why first]<sup>[citation]</sup>
- **Enables:** [What this unlocks]<sup>[citation]</sup>
- **Required information:** [What you need to know]<sup>[citation]</sup>

**Decision 2 (Month [timeframe]): [What to decide]**
- **Rationale:** [Why second, depends on Decision 1]<sup>[citation]</sup>
- **Enables:** [What this unlocks]<sup>[citation]</sup>
- **Required information:** [What Decision 1 reveals]<sup>[citation]</sup>

**Decision 3 (Month [timeframe]): [What to decide]**
- **Rationale:** [Why third, depends on Decision 1+2]<sup>[citation]</sup>
- **Outcome:** [Final positioning]<sup>[citation]</sup>

[Critical path and dependencies]
```

**Example:**
```markdown
**Decision 1 (Month 1-3): Deploy governance platform**
- **Rationale:** Enables all scenarios, no-regret move, prerequisite for compliance regardless of regulatory trajectory<sup>[1]</sup>
- **Enables:** Compliance readiness, operational visibility, risk management foundation
- **Required information:** Vendor capabilities (ModelOp, Fiddler, Arthur AI), internal requirements assessment

**Decision 2 (Month 4-9): Establish data collection infrastructure**
- **Rationale:** Depends on governance (need monitoring before collecting sensitive data), no-regret move valuable across scenarios<sup>[2]</sup>
- **Enables:** Proprietary dataset development, fine-tuning capabilities, differentiation regardless of model source
- **Required information:** Data quality requirements from governance platform, regulatory constraints identified in Decision 1

**Decision 3 (Month 10-18): Commit to model infrastructure (proprietary vs. open-source)**
- **Rationale:** Depends on 9-12 months of signal observation from Decision 2 data collection and governance monitoring<sup>[3]</sup>. Irreversible decision deferred until uncertainty reduces.
- **Outcome:** Locked-in infrastructure investment ($2-5M) aligned with clarified scenario direction
- **Required information:** Performance gap trajectory, regulatory clarity, proprietary data value demonstration from Decision 2

**Critical path:** Decision 1 must complete before Decision 2 (governance enables compliant data collection). Decision 2 must mature before Decision 3 (data collection reveals value, informs infrastructure needs). Attempting Decision 3 before Decision 1+2 creates 40-60% failure risk<sup>[4]</sup>.
```

---

### Pattern 4: Portfolio Rebalancing Triggers

**When to use:** Strategic portfolio needs dynamic adjustment as signals evolve

**Structure:**
```markdown
**Current allocation:**
- [X%] to [strategy type A]<sup>[citation]</sup>
- [Y%] to [strategy type B]<sup>[citation]</sup>
- [Z%] to [strategy type C]<sup>[citation]</sup>

**Rebalancing triggers:**

**Trigger 1: [Signal threshold]**
- **Action:** [How to rebalance]<sup>[citation]</sup>
- **Rationale:** [Why this indicates shift]<sup>[citation]</sup>

**Trigger 2: [Signal threshold]**
- **Action:** [How to rebalance]<sup>[citation]</sup>
- **Rationale:** [Why this indicates shift]<sup>[citation]</sup>

**Review frequency:** [How often to assess triggers]<sup>[citation]</sup>
```

**Example:**
```markdown
**Current allocation:**
- **60%** to robust strategies (deployment, governance, data)<sup>[1]</sup>
- **25%** to hedges (multi-jurisdiction, partnerships, compliance)<sup>[2]</sup>
- **15%** to conviction bet (commoditization assumption)<sup>[3]</sup>

**Rebalancing triggers:**

**Trigger 1: Open-source gap narrows to <8% (currently 15-20%)**
- **Action:** Shift 10% from robust to commoditization conviction bet (60%→50% robust, 15%→25% conviction)<sup>[4]</sup>
- **Rationale:** Gap <8% signals strong commoditization momentum—increase allocation to open-source infrastructure, data moat building

**Trigger 2: Regulatory divergence exceeds 35% (currently 25%)**
- **Action:** Shift 10% from robust to balkanization hedge (60%→50% robust, 25%→35% hedges)<sup>[5]</sup>
- **Rationale:** Divergence >35% signals persistent fragmentation—increase multi-jurisdiction capabilities, reduce global platform assumptions

**Trigger 3: Enterprise AI spending growth drops below 15% (currently 23%)**
- **Action:** Shift 10% from conviction bet to robust strategies (15%→5% conviction, 60%→70% robust)<sup>[6]</sup>
- **Rationale:** Spending slowdown signals uncertainty increase—reduce scenario bets, increase fundamental capabilities

**Trigger 4: Major platform partnership announcement (AWS-OpenAI equivalent)**
- **Action:** Shift 5-10% from commoditization to concentration conviction<sup>[7]</sup>
- **Rationale:** Deep integrations signal platform lock-in dynamics—adjust for concentration scenario

**Review frequency:** Monthly signal monitoring, quarterly portfolio rebalancing decisions<sup>[8]</sup>. Emergency rebalancing if triggers exceed thresholds by >50% (e.g., gap narrows to <4%, divergence hits 52%).
```

---

### Pattern 5: Option Value Preservation

**When to use:** Emphasizing decisions that maintain strategic flexibility

**Structure:**
```markdown
**Option to preserve: [Specific flexibility]**

**Option-preserving decision: [What to do now]<sup>[citation]</sup>**

**Option-killing alternative: [What to avoid]<sup>[citation]</sup>**

**Option exercise triggers: [When to convert option to commitment]<sup>[citation]</sup>**

**Option premium: [Cost of maintaining vs. committing]<sup>[citation]</sup>**

**Option value: [What flexibility is worth]<sup>[citation]</sup>**
```

**Example:**
```markdown
**Option to preserve:** Ability to switch AI providers (OpenAI → Anthropic → Open-source) within 6 months

**Option-preserving decision:** Build model-agnostic abstraction layer, use standardized APIs, containerized deployments<sup>[1]</sup>. Maintain relationships with 3+ vendors without exclusive commitments.

**Option-killing alternative:** Deep integration with single vendor (e.g., AWS Bedrock with Lambda tight coupling, Azure OpenAI with enterprise agreements)<sup>[2]</sup>. Creates 12-18 month lock-in, $400K-800K switching costs.

**Option exercise triggers:**
- **If commoditization confirmed (gap <5%):** Exercise option to switch to lowest-cost open-source provider<sup>[3]</sup>
- **If concentration confirmed (3 platforms control >80%):** Exercise option to join winning platform ecosystem<sup>[4]</sup>
- **If balkanization confirmed (divergence >40%):** Exercise option to deploy jurisdiction-specific models<sup>[5]</sup>

**Option premium:** Abstraction layer costs 20-30% more upfront ($300K vs. $230K) and adds 15-20ms latency overhead<sup>[6]</sup>. Annual maintenance: $40-60K for multi-vendor compatibility.

**Option value:** Expected value of switching flexibility over 3 years:
- 40% probability commoditization: Switch to open-source saves $800K<sup>[7]</sup>
- 35% probability concentration: Switch to winning platform avoids $400K in deprecated infrastructure<sup>[8]</sup>
- 25% probability balkanization: Multi-model deployment saves $600K in redundant builds<sup>[9]</sup>

Expected option value: (0.4 × $800K) + (0.35 × $400K) + (0.25 × $600K) = $610K
Option premium: $100K initial + ($50K × 3 years) = $250K
Net value: $360K positive—option worth preserving<sup>[10]</sup>
```

## Techniques Checklist

### Distinguish Decide-Now vs. Decide-Later

- [ ] **Clear criteria for timing**
  - Decide now: reversible, enabling, no-regret
  - Decide later: irreversible, wait-for-information, expensive

---

### Specify Information Triggers

- [ ] **Every "decide later" needs trigger**
  - ✓ "If gap narrows to <5%, then invest in open-source"
  - ✓ "If divergence exceeds 40%, then commit to single jurisdiction"
  - ✗ "Monitor situation and decide later"

---

### Quantify Cost of Waiting

- [ ] **State what's lost by delaying vs. gained by waiting**
  - Opportunity cost of delay
  - Risk reduction from waiting
  - Expected value calculation

Example:
> "Delaying 9-12 months means missing 15-20% market share opportunity ($400K revenue)<sup>[1]</sup>. But premature commitment creates $1-2M stranded asset risk<sup>[2]</sup>. Expected value favors waiting: (0.6 × $1.5M saved) - (0.4 × $400K lost) = +$740K."

---

### Sequence Dependent Decisions

- [ ] **Identify decision dependencies**
  - What must happen first
  - What information earlier decisions reveal
  - Critical path identification

## Quality Checkpoints

### Content Requirements

- [ ] Decide-now items specified (2-4 items)
- [ ] Decide-later items specified with triggers (2-4 items)
- [ ] Information monitoring approach defined
- [ ] Decision sequencing explained
- [ ] At least 5 citations

### Structure Requirements

- [ ] Decision specification section (250-350 words)
- [ ] Word count: 250-350 words (±50 tolerance)
- [ ] Smooth transition from Strategies
- [ ] Closing emphasizes learning and adaptation

### Decision Quality

- [ ] Every decision has timeframe
- [ ] Triggers are specific and measurable
- [ ] Reversibility assessed per decision
- [ ] Cost of waiting vs. committing analyzed
- [ ] Sequencing logic clear

## Common Mistakes

### ❌ Mistake 1: All Decisions Now or All Decisions Later

**Bad:**
> "Make all major strategic decisions immediately to avoid falling behind."

**Why it fails:** Ignores value of waiting for information under uncertainty.

**Good:**
> "Decide now: governance deployment (reversible, no-regret), data collection (enables learning). Decide later: major infrastructure investment (irreversible, wait for signal clarity on commoditization vs. concentration)<sup>[1]</sup>."

**Why it works:** Balances action with optionality preservation.

---

### ❌ Mistake 2: Vague Triggers

**Bad:**
> "Wait for more clarity on regulatory environment before committing to jurisdiction."

**Why it fails:** No specific threshold for "more clarity."

**Good:**
> "Wait for regulatory divergence clarity. If EU-US requirement overlap drops below 60% (currently 70%), signals fragmentation—commit to single jurisdiction<sup>[1]</sup>. Monitor quarterly through regulatory tracking service."

**Why it works:** Specific threshold (60%), measurement approach (overlap %), monitoring frequency.

---

### ❌ Mistake 3: No Cost-of-Waiting Analysis

**Bad:**
> "Delay model infrastructure investment until scenario clarity emerges."

**Why it fails:** Doesn't assess opportunity cost of delay.

**Good:**
> "Delaying infrastructure investment 12 months means missing $400K early adopter revenue<sup>[1]</sup>. But premature commitment risks $1.5M stranded assets if wrong scenario<sup>[2]</sup>. Expected value: (0.6 × $1.5M) - (0.4 × $400K) = +$740K favors waiting."

**Why it works:** Quantifies both sides, calculates expected value.

---

### ❌ Mistake 4: Ignoring Decision Dependencies

**Bad:**
> "Deploy governance platform, collect proprietary data, and commit to model infrastructure simultaneously."

**Why it fails:** Misses dependencies—infrastructure decision depends on data insights.

**Good:**
> "Phase 1 (M1-3): Deploy governance (enables compliant data collection). Phase 2 (M4-9): Collect data (reveals infrastructure needs). Phase 3 (M10-18): Commit to infrastructure based on Phase 2 learnings<sup>[1]</sup>. Dependencies require sequencing."

**Why it works:** Recognizes information flow, sequences accordingly.

---

### ❌ Mistake 5: Static Portfolio, No Rebalancing

**Bad:**
> "Allocate 60% robust, 25% hedges, 15% conviction and maintain indefinitely."

**Why it fails:** Doesn't adapt as signals evolve and uncertainty resolves.

**Good:**
> "Start 60-25-15 allocation. Rebalance quarterly based on triggers: If gap <8%, shift 10% to conviction. If divergence >35%, shift 10% to hedges. If spending growth <15%, shift to robust<sup>[1]</sup>. Dynamic allocation responds to learning."

**Why it works:** Adapts to new information, reduces uncertainty exposure.

## Language Variations

### German Adjustments

**Decision terminology:**
- "Sofort-Entscheidungen" (decide-now)
- "Später-Entscheidungen" (decide-later)
- "Informations-Trigger" (information triggers)

**Trigger specification:**
- German planning culture expects precise thresholds
- Include exact metrics, not ranges

**Expected value calculation:**
- Show full probability-weighted calculations
- Include downside and upside scenarios

**Example (German style):**
```markdown
**Sofort-Entscheidungen (0-6 Monate):**

**Governance-Infrastruktur deployen:** Wertvoll über alle Szenarien, reversibel falls Prioritäten shiften, ermöglicht Compliance-Readiness<sup>[1]</sup>. Entscheidung: ModelOp vs. Fiddler vs. Arthur AI. Timeline: 3 Monate Vendor-Selection, 3 Monate Deployment. Kosten: €180-250K initial, €40-60K annual.

**Multi-Jurisdictions-Präsenz etablieren:** Low-Cost Footprint in EU + US + Asien via Partnerships oder kleine Teams (€180-360K)<sup>[2]</sup>. Schafft Optionalität falls Regulatory-Fragmentierung eintritt. Reversibel durch Team-Redeployment falls Konvergenz erfolgt.

---

**Später-Entscheidungen (warten auf Signale):**

**Major Model-Infrastructure-Investment (€1,8-4,5M):** Warten auf Commoditization vs. Concentration Clarity<sup>[3]</sup>. Premature Commitment schafft Stranded Assets falls Szenario nicht wie erwartet eintritt.

**Trigger:** Falls Open-Source-Models <5% Performance-Gap erreichen zu Proprietary (aktuell 15-20%), signalisiert Commoditization—investieren in Open-Source-Infrastructure<sup>[4]</sup>. Falls Gap weitet zu >25%, signalisiert Concentration—investieren in Platform-Partnerships.

**Monitoring:** Monatlich Benchmark-Tracking (MMLU, HumanEval), Quarterly Performance-Gap-Analyse<sup>[5]</sup>.

**Expected Value Kalkulation (12-Monate Delay):**
- Opportunity Cost: €360K Early-Adopter-Revenue entgeht<sup>[6]</sup>
- Risk Reduction: €1,35M Stranded-Asset-Risiko vermieden bei falschem Szenario<sup>[7]</sup>
- Probability-Weighted: (0,6 × €1,35M) - (0,4 × €360K) = +€666K

**Fazit:** Expected Value favorisiert Warten trotz Opportunity Cost.
```

## Related Patterns

- See `signals-patterns.md` for monitoring weak signals that trigger decisions
- See `scenarios-patterns.md` for understanding what decisions matter per scenario
- See `strategies-patterns.md` for robust strategies being executed through decisions
