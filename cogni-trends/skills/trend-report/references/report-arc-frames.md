# Report-Level Arc Frames

This reference defines how the user-selected story arc shapes the **report-level** narrative — executive summary framing, bridge paragraphs between investment themes, synthesis section, and optional theme sequencing. It does NOT change how individual investment theme sections are written (those always use the `theme-thesis` arc internally).

The report-level arc is the reader's narrative experience: it determines the **voice**, **rhetorical frame**, and **connective logic** that bind 3-7 investment themes into one cohesive story instead of N independent mini-reports.

---

## Arc Selection

Present the user with 7 arcs via `AskUserQuestion` in Phase 0 Step 0.4b. The recommended default depends on content:

| Content Signal | Recommended Arc |
|---------------|-----------------|
| TIPS trend-scout output (default) | `corporate-visions` |
| Technology-heavy topics (IoT, AI, R&D) | `technology-futures` |
| Competitive positioning focus | `competitive-intelligence` |
| Long-range planning (5-10+ years) | `strategic-foresight` |
| Industry regulation / structural change | `industry-transformation` |
| TIPS dimension overview (no value model) | `trend-panorama` |
| Single investment theme deep-dive | `theme-thesis` |

The orchestrator auto-detects the recommended default from the trend-scout config (industry, topic keywords) but the user always has final say.

---

## Per-Arc Framing Templates

Each arc template covers four components:
1. **Exec Summary Opener** — The rhetorical frame for the first 2-3 sentences
2. **Exec Summary Closer** — The closing paragraph's vocabulary and structure
3. **Bridge Pattern** — How consecutive themes connect (N-1 bridges for N themes)
4. **Synthesis Frame** — The 300-500 word closing section after the last theme
5. **Sequencing Heuristic** — How to optionally reorder themes for narrative impact

---

### 1. Corporate Visions (Default)

**Arc ID:** `corporate-visions`
**Report Voice:** Challenger sale — challenge assumptions, create urgency, present capability, quantify inaction

**Exec Summary Opener:**
The unconsidered need pattern. Challenge the reader's mental model with the most surprising reframe across all themes. Lead with a specific data point that contradicts conventional wisdom.
Pattern: "The prevailing assumption in [industry] is [X]. [N] analyzed trends reveal: [reframe]. [Striking data point]."

**Exec Summary Closer:**
Aggregate cost-of-inaction framing. Combine the strongest why-pay ratios from all themes into a single decisive investment window.
Pattern: "Together these [N] investment themes create a [time window]. Proactive investment: €X M. Cost of inaction: €Y M over three years. The ratio is clear: acting costs [fraction] of waiting."

**Bridge Pattern:**
Each bridge connects themes through the lens of compounding pressure — each theme intensifies the urgency established by the previous one.
Pattern: "The [capability gap / unconsidered need] from [Theme N] compounds when [evidence from Theme N+1]. [One sentence showing how delayed action in Theme N makes Theme N+1 more expensive]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "The Investment Decision" / "Die Investitionsentscheidung")
Aggregate all why-pay dimensions across themes. Present a unified 3-year cost-of-inaction vs. proactive-investment calculation. Close with a single decisive ratio and a unified action roadmap (3-4 bullets with calendar dates) that supersedes per-theme action steps.

**Sequencing Heuristic:**
Lead with the theme that has the strongest unconsidered need (most surprising reframe / highest why-pay ratio). End with the theme that has the broadest foundation implications (creates urgency for the reader to start immediately).

---

### 2. Technology Futures

**Arc ID:** `technology-futures`
**Report Voice:** Innovation scout — map emerging capabilities, show convergence, quantify required investment

**Exec Summary Opener:**
Convergence pattern. Open with the most surprising technology convergence across themes — two or more emerging capabilities that, combined, create an outcome neither achieves alone.
Pattern: "[N] technology trends are converging in [industry]: [capability A] meets [capability B], enabling [outcome]. The question is not whether — but who captures this first."

**Exec Summary Closer:**
Capability readiness framing. The closing quantifies the organizational capabilities required and the window to build them.
Pattern: "These [N] investment themes require [capability summary]. Organizations that begin building now gain [N] months of learning advantage. The technology is ready — organizational readiness is the bottleneck."

**Bridge Pattern:**
Each bridge shows how one theme's emerging technology enables or accelerates the next theme's possibilities.
Pattern: "The [emerging capability] from [Theme N] becomes the enabling infrastructure for [Theme N+1]. [One sentence: without Theme N's foundation, Theme N+1's potential remains theoretical]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "What's Required" / "Was erforderlich ist")
Unified capability roadmap across all themes. Map required organizational capabilities (talent, infrastructure, data, governance) and show which are shared foundations vs. theme-specific. Close with a build-vs-buy assessment and a phased capability timeline.

**Sequencing Heuristic:**
Lead with the most mature/proven emerging technology (closest to production). End with the most forward-looking possibility (creates a vision of what's at stake).

---

### 3. Competitive Intelligence

**Arc ID:** `competitive-intelligence`
**Report Voice:** Strategic analyst — map the landscape, identify shifts, position for advantage

**Exec Summary Opener:**
Landscape disruption pattern. Open with the most significant competitive shift across themes — a structural change that redefines who wins.
Pattern: "The competitive landscape in [industry] is being redrawn by [N] converging forces. [Specific shift]. Organizations that recognize this shift gain positioning advantage; those that don't face structural disadvantage."

**Exec Summary Closer:**
Strategic positioning framing. Close with the implications of the combined shifts for competitive positioning.
Pattern: "Across [N] investment themes, one pattern emerges: [positioning insight]. The window for repositioning narrows as [forcing function]. First movers capture [advantage]; followers compete on cost."

**Bridge Pattern:**
Each bridge shows how one theme's competitive shift creates openings or threats that the next theme addresses.
Pattern: "The [competitive shift] from [Theme N] creates a strategic opening in [Theme N+1's domain]. [One sentence: organizations that miss Theme N's window face compounded disadvantage in Theme N+1]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "Strategic Implications" / "Strategische Implikationen")
Integrated competitive positioning assessment. Synthesize how the combined themes reshape the competitive landscape, identify the 2-3 most defensible strategic positions, and close with a "move now" imperative grounded in competitive dynamics.

**Sequencing Heuristic:**
Lead with the broadest landscape-changing force. End with the theme that creates the most defensible competitive moat.

---

### 4. Strategic Foresight

**Arc ID:** `strategic-foresight`
**Report Voice:** Futurist advisor — read signals, build scenarios, frame decisions under uncertainty

**Exec Summary Opener:**
Signal convergence pattern. Open with the strongest signals of change, emphasizing that multiple independent indicators point to the same future.
Pattern: "Across [industry], [N] independent signals point to a structural shift: [insight]. These are not predictions — they are observable, measurable changes already underway."

**Exec Summary Closer:**
Decision framing under uncertainty. Close by framing the strategic choice as a portfolio of bets, not a single decision.
Pattern: "The signals are clear; the scenarios are bounded. [N] investment themes define the decision space. Organizations that hedge across these themes preserve optionality. Those that commit to one path risk [consequence]. The optimal strategy: [hedging approach]."

**Bridge Pattern:**
Each bridge traces how signals from one theme create scenarios that the next theme must navigate.
Pattern: "The signals identified in [Theme N] produce scenarios where [Theme N+1's domain] becomes [critical / disrupted / transformed]. [One sentence: the uncertainty in Theme N amplifies the stakes in Theme N+1]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "The Decisions Ahead" / "Die anstehenden Entscheidungen")
Scenario-based decision framework. Present 2-3 plausible scenarios that emerge from combining all themes, identify the no-regret moves (actions that pay off in all scenarios), and close with a decision timeline tied to signal checkpoints.

**Sequencing Heuristic:**
Lead with the theme with the strongest, most measurable signals. End with the theme that contains the highest uncertainty / optionality value.

---

### 5. Industry Transformation

**Arc ID:** `industry-transformation`
**Report Voice:** Transformation advisor — identify forces, acknowledge friction, chart evolution, define leadership

**Exec Summary Opener:**
Macro forces pattern. Open with the dominant structural forces reshaping the industry — regulation, demographics, technology, geopolitics.
Pattern: "[N] structural forces are transforming [industry] simultaneously: [force 1], [force 2], [force 3]. Unlike cyclical pressures, these forces are irreversible — and they're accelerating."

**Exec Summary Closer:**
Leadership positioning framing. Close with what defines industry leadership in the transformed landscape.
Pattern: "Industry leadership in [industry] by [year] will not be defined by [traditional metric]. It will be defined by [new metric]. These [N] investment themes chart the transformation path. Organizations that lead the transformation write the new rules; followers operate within them."

**Bridge Pattern:**
Each bridge shows how forces from one theme create friction or evolution in the next theme's domain.
Pattern: "The [structural force] driving [Theme N] creates both friction and opportunity in [Theme N+1's domain]. [One sentence: the organizations that resolve Theme N's friction first gain acceleration in Theme N+1]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "Leadership Positioning" / "Führungspositionierung")
Transformation leadership assessment. Synthesize what it means to lead (not just survive) across all themes. Identify the 2-3 defining leadership capabilities, the timeline for building them, and the cost of following instead of leading.

**Sequencing Heuristic:**
Lead with the strongest external force (regulation > demographics > technology > market). End with the theme that defines the target leadership position.

---

### 6. Trend Panorama (TIPS-Native)

**Arc ID:** `trend-panorama`
**Report Voice:** Trendradar analyst — map forces, trace impact chains, scan horizons, build foundations

**Exec Summary Opener:**
Force-to-foundation pattern. Open with the most powerful external force and trace its impact chain through to foundation requirements.
Pattern: "[N] trends across [industry] reveal a single through-line: [external force] → [value driver impact] → [horizon opportunity] → [foundation requirement]. The force is external; the response is strategic."

**Exec Summary Closer:**
Foundation urgency framing. Close by emphasizing that trend awareness without foundation investment is strategic theater.
Pattern: "Identifying trends is necessary but insufficient. These [N] investment themes share [M] common foundation requirements. Without these foundations, opportunities remain theoretical. The investment sequence matters: foundations first, then horizon plays."

**Bridge Pattern:**
Each bridge traces the TIPS chain — how forces in one theme create impact that the next theme must capture.
Pattern: "The [force / impact] from [Theme N] creates [opportunity / foundation need] that [Theme N+1] directly addresses. [One sentence: the themes form a causal chain, not a menu of independent options]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "Strategic Foundations" / "Strategische Grundlagen")
Unified foundation assessment across themes. Identify shared foundation requirements (data infrastructure, talent, governance), theme-specific foundations, and the build sequence that maximizes the number of themes unlocked per investment euro.

**Sequencing Heuristic:**
Lead with the theme driven by the strongest external force (T-dimension). End with the theme that has the deepest foundation requirements (S-dimension).

---

### 7. Theme Thesis

**Arc ID:** `theme-thesis`
**Report Voice:** Investment advisor — each theme is an investment thesis with its own business case

**Exec Summary Opener:**
Investment portfolio pattern. Open by framing the themes as a portfolio of strategic investments, each with its own risk-return profile.
Pattern: "[N] strategic investments define the agenda for [industry] over the next [timeframe]. Each carries a distinct thesis — and a quantified cost of inaction."

**Exec Summary Closer:**
Portfolio return framing. Close with the aggregate portfolio return vs. aggregate cost of delay.
Pattern: "As a portfolio, these [N] investments require €X M and return [Y]. Individually, each theme's cost-of-inaction exceeds its investment by [ratio]. The portfolio logic is simple: the cost of doing nothing always exceeds the cost of acting."

**Bridge Pattern:**
Each bridge frames the transition as portfolio construction — how adding the next theme strengthens the overall investment thesis.
Pattern: "[Theme N]'s investment in [capability] creates optionality for [Theme N+1]. [One sentence: the portfolio effect — themes compound each other's returns when invested together]."

**Synthesis Frame:**
**Heading:** `{SYNTHESIS_HEADING}` (i18n: "Aggregate Investment Case" / "Aggregierter Investitionsfall")
Combined business case across all themes. Aggregate total investment required, total cost of inaction, portfolio return ratio, shared infrastructure investments (invest once, unlock multiple themes), and a prioritized investment sequence based on time-sensitivity and dependency order.

**Sequencing Heuristic:**
Lead with the theme with the most time-sensitive forcing function (closest regulatory deadline). End with the theme that creates the broadest strategic optionality.

---

## Bridge Paragraph Format

Each bridge paragraph is rendered as a transitional blockquote between theme sections:

```markdown
> **[BRIDGE_LABEL]:** [2-4 sentences using the selected arc's bridge pattern. Must reference specific
> evidence from both the preceding and following theme — numbers, entities, or deadlines. Generic
> transitions like "Building on the previous theme" are insufficient. The bridge must demonstrate
> a causal or strategic link between the themes.]
```

The bridge is NOT a summary. It's a narrative joint that creates forward momentum — the reader should feel that the next theme is an inevitable consequence of what they just read.

**Quality gate:** Every bridge must contain at least one specific data point from the preceding theme AND one from the following theme.

---

## Synthesis Section Format

The synthesis section replaces the pattern where each theme ends with its own "Nächste Schritte" and the report simply stops after the last theme. Instead:

1. Per-theme "Nächste Schritte" remain (they're specific and actionable per-theme)
2. The synthesis section adds a **unified strategic frame** after the last theme
3. It aggregates across themes (total investment, total cost-of-inaction, shared foundations)
4. It provides a **unified action roadmap** (3-4 bullets with calendar dates) that sequences across themes

```markdown
## {SYNTHESIS_HEADING}

{Opening: 2-3 sentences through the arc's synthesis lens — e.g., for corporate-visions,
the aggregate investment decision; for strategic-foresight, the scenario-based decision framework}

{Body: 200-350 words that:
- Aggregate the strongest evidence across themes
- Identify shared foundations / investments that unlock multiple themes
- Present the combined cost-of-inaction vs. proactive investment
- Apply the arc's specific synthesis technique}

{Unified Action Roadmap:}
1. **{Calendar timeframe}**: {Cross-theme action — names which themes it enables}
2. **{Calendar timeframe}**: {Cross-theme action}
3. **{Calendar timeframe}**: {Cross-theme action}

{Closing: 1-2 sentences — the arc's decisive closing statement}
```

Must end with two trailing newlines.
