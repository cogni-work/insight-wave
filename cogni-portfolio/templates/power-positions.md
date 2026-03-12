# Corporate Visions Power Position framework for LLM-driven messaging

The Power Position is a three-layer messaging pyramid — **What It Is / What It Does / What It Means** — designed to move B2B product descriptions from feature-centric to buyer-outcome-centric language. Developed by Tim Riesterer and Erik Peterson at Corporate Visions and codified in Chapter 11 of *Conversations That Win the Complex Sale* (McGraw-Hill, 2011), the framework has been deployed in over **2,000 messaging engagements** across companies including GE, Oracle, Dell, and SAP. For an LLM-based portfolio messaging tool, the framework provides a reliable, rules-based structure: each layer has distinct linguistic patterns, quality tests, and anti-patterns that translate directly into generative constraints and evaluation rubrics.

The critical insight underlying the framework is that **most companies over-invest messaging at the "Is" level** — feature dumps, technical specs, company history — which is the layer buyers care about least. The pyramid inverts this: the "Means" layer (business/personal impact) drives decisions, the "Does" layer (functional capability) creates buying vision, and the "Is" layer (features/facts) merely anchors credibility.

---

## The three layers defined and operationalized

### Layer 1: "What It Is" (base of the pyramid)

**Definition:** The factual, technical description of the product, service, or capability — its name, category, features, and specifications. Corporate Visions defines this as "the product your customer actually buys: the name of your solution, and its features and functions."

**Purpose in the structure:** Provides grounding and credibility. It tells the reader *what* they're looking at in concrete terms. It should be the shortest, most restrained layer.

**Checklist for a strong "What It Is" statement:**

- Uses a clear, recognizable product/service category name (e.g., "cloud-based analytics platform," not vague labels like "next-gen solution")
- Stays under **one to two sentences** — brief enough to be a factual anchor, not a feature catalog
- Uses concrete, specific descriptors rather than marketing adjectives ("multi-colored cloth system" not "innovative cleaning technology")
- Frames technical details in the buyer's vocabulary, not internal product jargon
- Includes only the features that are necessary to set up the "Does" layer — selective, not exhaustive
- Avoids buzzwords and parity language: no "robust," "world-class," "enterprise-grade," "cutting-edge," or "best-in-class"
- Does **not** lead with "We are..." or company history — keeps focus on the offering itself

**Anti-patterns to flag and reject:**

- Feature-dumping: listing every specification, integration, or capability
- Using the "Is" layer as the entire message (the most common failure Corporate Visions identifies)
- Internal naming conventions or acronyms the buyer wouldn't recognize
- Undifferentiated boilerplate that any competitor could copy verbatim

**Example — cleaning service:** "Multi-colored cloth system" (a factual, concrete "Is" that sets up what it does differently).

**Example — cell phone:** "Plastic, glass, metal, battery, rubber, circuit boards" — illustrates that raw "Is" facts alone are uncompelling. The LLM should generate the minimal viable "Is" and move quickly to "Does."

---

### Layer 2: "What It Does" (middle of the pyramid)

**Definition:** What the buyer can **do differently or better** with this capability. Corporate Visions calls this "your power position statement: what your customer can do better with your solution. Use this statement to tell your story in the shortest way possible." This is the **HOW** level — the mechanism of value delivery.

**Purpose in the structure:** This layer is the pivot point where ownership of the story transfers from seller to buyer. Corporate Visions emphasizes that this is "most compelling to your customer: it shows them what they'll be able to do more effectively by choosing your solution." The "Does" layer creates **buying vision** — the prospect sees themselves operating differently.

**Checklist for a strong "What It Does" statement:**

- Written from the **buyer's perspective** using "you" language ("you can eliminate..." not "it provides...")
- Describes a **buyer action or capability**, not a product function ("you can diagnose patients faster" not "the platform processes data in real-time")
- Includes an implicit or explicit **contrast with the current approach** — what changes? What's different? What was previously impossible or painful?
- Ties directly to a differentiator that is **unique to this product** — not a capability every competitor offers (the Value Wedge test)
- Bridges logically from the "Is" to the "Means" — the mechanism should make the outcome plausible
- Is specific enough to be credible but concise enough to be conversational — **one to three sentences**
- Passes the "Snicker Test": a salesperson could say it aloud without cringing or sounding artificial
- Uses active verbs and concrete nouns, not abstract process language

**Anti-patterns to flag and reject:**

- Describing what the **product** does instead of what the **buyer** can do (vendor-centric framing)
- Using "we" or "our solution" as the subject of the sentence
- Listing generic functional capabilities without connecting them to the buyer's workflow
- Stopping at the functional level without implying or explicitly stating the outcome
- Stating capabilities that are **parity** — any competitor could make the same claim
- Using passive voice or nominalized verbs ("provides optimization" instead of "you can optimize...")

**Example — cleaning service:** "Eliminates the risk of cross-contamination that comes from cleaning everything with the same cloth." Notice: buyer-relevant risk framed as what the service *does differently*, not just what the cloth *is*.

**Example — Tylenol:** "Relieves your pain without upsetting your stomach." The contrast with alternatives (implied stomach upset from aspirin) is baked into the "Does" statement — a model for competitive differentiation within the layer.

**Critical LLM instruction:** Corporate Visions warns that "where most sales pros drop the ball is in explaining what the customer will be able to Do differently with their solution versus anyone else's." The LLM should be explicitly prompted to generate the "Does" layer *before* the "Is" layer in its reasoning chain, even if the output order is Is → Does → Means. This prevents the common failure of letting features drive the message.

---

### Layer 3: "What It Means" (top of the pyramid)

**Definition:** The business and personal impact — what doing something differently will *mean* to the buyer's organization and career. This is the **WHY** level. Corporate Visions defines it as "where you communicate the value your customer will see from making a change — and from choosing you."

**Purpose in the structure:** This layer drives the actual decision. It connects functional capability to outcomes the buyer's organization measures and the buyer personally cares about. Corporate Visions' methodology is grounded in behavioral science showing that **loss aversion** (Kahneman's Prospect Theory) and emotional relevance in the "old brain" are the real decision mechanisms — not logical feature comparison.

**Checklist for a strong "What It Means" statement:**

- Articulates a **measurable business outcome**: revenue increase, cost reduction, risk elimination, time savings, compliance achieved — with specificity where possible
- Includes **personal/emotional impact** where appropriate: less stress, career protection, reputation enhancement, reduced firefighting, more strategic time
- Uses or implies quantification: "$1.2M in first-year savings" is stronger than "significant cost reduction"
- Can be framed as a **"What if you could..." question** to create buying vision (e.g., "What if you could redirect 30% of your team's time from troubleshooting to strategic projects?")
- Connects to the buyer's **stated or anticipated business objectives** — not to what excites the seller's marketing team
- Passes the **"So What?" test**: if a buyer reads this and can still say "so what?", the statement hasn't reached the true "Means" level
- Is **memorable** — uses contrast, concrete imagery, or a surprising frame rather than generic outcome language
- Does not merely restate the "Does" layer with an outcome verb prepended — it should represent a genuine escalation in impact level

**Anti-patterns to flag and reject:**

- Vague, unquantified claims: "improves efficiency," "drives value," "enhances productivity," "delivers ROI"
- Staying purely rational/logical without any emotional or personal dimension
- Generic superlatives: "best-in-class results," "world-class outcomes," "industry-leading performance"
- Sounding like a press release or investor pitch rather than a buyer conversation
- Repeating the "Does" statement with slightly different wording instead of escalating to impact
- Using outcomes that are **not connected** to the specific "Does" claim — the causal chain must be clear

**Example — cleaning service:** "Creates a healthier work environment with fewer sick days and improved productivity." Business outcome (fewer sick days, improved productivity) flows directly from the "Does" (eliminates cross-contamination).

**Example — Tylenol:** "You'll be able to be more productive at work because you don't have either a headache or a stomachache." Personal + professional impact, directly chained to the "Does."

**Example — Ford/Cadillac (quantified):** "4% scrap rate equals $360,000 in savings; zero bad engines; $1.2 million first-year savings versus $275,000 investment." This is the gold standard — specific numbers that make the "Means" irrefutable. Ford bought two systems on the spot after a 12-minute presentation.

---

## The three qualifying gates every Power Position must pass

Before any Is/Does/Means statement is considered complete, it must satisfy the **Value Wedge** test — three criteria that Corporate Visions treats as non-negotiable:

1. **Unique to you** — The claim cannot be something every competitor offers. If a rival could swap in their name and the statement would still be true, it fails. This is the most common failure mode in B2B messaging: "value parity" where everyone sounds the same.

2. **Important to the customer** — The claim must connect to a real buyer need, pain, or desired outcome. An internally impressive capability that buyers don't care about is not a Power Position.

3. **Defensible with evidence** — The claim must be provable through customer stories, data, demonstrations, or third-party validation. If challenged, you can back it up.

For the LLM tool, these three gates function as a **validation layer** that should run after generation. The system should flag any Power Position where the "Does" or "Means" layer could apply equally to known competitors, where the stated outcome doesn't map to a documented buyer priority, or where no supporting evidence exists in the portfolio data.

---

## Five quality tests for evaluating generated statements

Corporate Visions provides a broader evaluation framework with five tests, which can serve as a scoring rubric for LLM output:

1. **Is the message unique to this product/solution?** Score 0 if any competitor could make the identical claim.
2. **Is it important to the target buyer persona?** Score 0 if it addresses a need the buyer hasn't expressed or doesn't prioritize.
3. **Can the claim be defended and proved?** Score 0 if no evidence, case study, or data point exists to support it.
4. **Is it memorable?** Score 0 if the reader would forget the statement within 60 seconds. Memorable statements use contrast, specific numbers, vivid imagery, or surprising frames.
5. **Does it truly differentiate in the marketplace?** Score 0 if the statement reinforces parity rather than creating separation from alternatives.

Additionally, every statement should pass two practical tests: the **"Snicker Test"** (could a salesperson say this aloud without cringing?) and the **"So What?" Test** (would a buyer's immediate reaction be "so what?" — if yes, the statement hasn't reached the "Means" level).

---

## How Power Positions nest within the broader messaging architecture

Power Positions don't exist in isolation. They sit within a layered Corporate Visions methodology that the LLM tool may eventually need to reference:

**The Customer Deciding Journey** organizes buyer decisions into four value conversations, each answered by specific "Why" questions. Power Positions primarily serve the **"Why You"** conversation (Create Value phase) but anchor messaging across all phases.

The four "Why" conversations are: **Why Change** (defeating the status quo — 60% of qualified pipeline is lost to "no decision," not to competitors), **Why Now / Why Invest** (building the business case for budget release), **Why You** (where Power Positions live — differentiating against alternatives), and **Why Pay** (defending pricing and avoiding discounts). A fourth conversation, **Why Stay / Why Evolve / Why Forgive**, handles retention and expansion with existing customers.

**Unconsidered Needs** are problems the buyer doesn't yet recognize — undervalued, unmet, or unknown challenges. Corporate Visions research with Stanford's Dr. Zakary Tormala showed that introducing unconsidered needs *before* stated needs produced a **50% increase in perceived differentiation** and a **10% increase in persuasion**. For the LLM tool, this means the "Does" and "Means" layers are most powerful when they connect to needs the buyer hasn't fully articulated, not just needs they already know about.

**The Conversation Roadmap** is the final deliverable that organizes everything into a story flow: Grabber (attention-spiking industry insight) → Pain (the unconsidered need) → Old Way vs. New Way Contrast → Solution with Power Positions → Customer Proof Story. Each Power Position should also be supported with three messaging components: a **Wow** (grabber technique — "What if you could..." questions, number plays, stories with contrast), a **How** (the mechanism), and **Proof** (customer evidence).

---

## Practical generation patterns for the LLM tool

Based on the research, here is a recommended generation workflow for the cogni-portfolio system:

**Step 1: Identify the differentiator.** From the input data (product specs, competitive landscape, buyer persona), extract what is unique, important, and defensible. If nothing passes the Value Wedge test, flag the input as insufficient.

**Step 2: Draft the "Does" layer first.** Corporate Visions' own guidance is that messaging should *start* at the "Does" level, not the "Is" level. Prompt the LLM to articulate what the buyer can do differently or better, using "you" language and active verbs, before generating the "Is" or "Means" layers.

**Step 3: Escalate to "Means."** From the "Does" statement, generate the business and personal impact. Push for specificity: numbers, timeframes, named outcomes. Test with the "So What?" filter — if the output is generic ("improved efficiency"), regenerate with a prompt to be more concrete.

**Step 4: Anchor with "Is."** Generate the minimal factual description — category, key features, technical grounding — sufficient to make the "Does" claim credible. Resist feature-dumping.

**Step 5: Validate.** Run the five quality tests. Check for "you" language prevalence over "we/our." Check for parity language. Check that the causal chain Is → Does → Means is logically coherent. Flag any layer that could be claimed by a named competitor.

**Recommended output format per capability:**

- **What It Is:** 1-2 sentences. Factual, concrete, category-clear.
- **What It Does:** 1-3 sentences. Buyer-centric, action-oriented, differentiated.
- **What It Means:** 1-2 sentences. Outcome-specific, quantified where possible, emotionally resonant.

The entire Power Position should be **concise enough to be spoken aloud in a natural sales conversation** — roughly 50-100 words total across all three layers. Corporate Visions recommends **three Power Positions per product or solution** to align with the Rule of Three for memorability.

---

## Conclusion: from framework to LLM constraints

The Power Position framework's strength for LLM implementation lies in its rigid structural rules and testable quality criteria. Each layer has a distinct linguistic signature: "Is" uses noun phrases and factual descriptors, "Does" uses second-person active constructions ("you can..."), and "Means" uses outcome and impact language with quantification. The Value Wedge provides a binary pass/fail gate (unique + important + defensible), and the five quality tests provide a scoring rubric.

The most actionable insight for building cogni-portfolio is that the framework's failure modes are well-documented and predictable — feature-dumping, vendor-centric language, parity claims, and vague outcomes — making them straightforward to detect and correct in generated output. Corporate Visions' own finding that **most companies default to "Is"-level messaging** means the LLM should be explicitly weighted toward generating and prioritizing the "Does" and "Means" layers, with the "Is" layer serving as the minimal credibility anchor rather than the message's center of gravity.