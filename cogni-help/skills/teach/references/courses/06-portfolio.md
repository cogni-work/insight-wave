# Course 6: Portfolio Messaging

**Duration**: 45 minutes | **Modules**: 6 | **Prerequisites**: Course 3
**Plugins**: cogni-consulting (business-model-hypothesis), cogni-portfolio
**Audience**: Consultants building product/service portfolios for SMEs

---

## Module 1: Lean Canvas — Your Starting Hypothesis

### Theory (3 min)

Before diving into portfolio messaging, you need a business hypothesis. The
**business-model-hypothesis** vision class in **cogni-consulting** helps you build a
research-backed **Lean Canvas** — a one-page business model that captures the core
assumptions about your product/service:

| Section | Question | Example |
|---------|----------|---------|
| **Problem** | Top 3 problems you're solving | "Manual compliance reporting takes 40+ hours/month" |
| **Customer Segments** | Who has these problems? | "Mid-market financial services firms in DACH" |
| **Unique Value Proposition** | Why are you different? | "Automated compliance with real-time audit trail" |
| **Solution** | Top 3 features that solve the problems | "Rule engine, report generator, audit dashboard" |
| **Channels** | How do you reach customers? | "Partner network, industry events, content marketing" |
| **Revenue Streams** | How do you make money? | "SaaS subscription, implementation services" |
| **Cost Structure** | Key costs | "Engineering, cloud hosting, sales team" |
| **Key Metrics** | Numbers that matter | "MRR, customer retention, time-to-compliance" |
| **Unfair Advantage** | What can't be copied? | "15 years of regulatory domain expertise" |

**Why start here**: The canvas forces you to articulate assumptions before investing
in detailed messaging. It's cheaper to refine a hypothesis than to rework a full
portfolio.

**Two consulting methods**:
- `lean-canvas-authoring` — guided Q&A to build a new canvas from scratch
- `lean-canvas-refinement` — critique and improve an existing canvas section by section

### Demo

Walk through canvas creation:
1. Run `lean-canvas-authoring` via cogni-consulting and observe the guided Q&A flow
2. Show how the 9 sections build on each other
3. Show the resulting markdown file with YAML frontmatter (version tracking, section status)
4. Demonstrate `lean-canvas-refinement` — critique one section and improve it
5. Preview: how `portfolio-canvas` will extract entities for the rest of this course

### Exercise

Ask the user to:
1. Think of a product or service they know well (their own or a client's)
2. Run `lean-canvas-authoring` via cogni-consulting or fill in a canvas manually
3. Focus on Problem, Customer Segments, and Unique Value Proposition first
4. Check: does the UVP actually address the problems for those segments?

Create `_teacher-exercises/canvas-draft.md` with a template if the user prefers manual entry.

### Quiz

1. **Multiple choice**: Why should you start with a Lean Canvas before portfolio messaging?
   - a) Because it's required by the plugin
   - b) It forces you to articulate assumptions cheaply before investing in detailed messaging
   - c) It replaces the need for portfolio messaging entirely
   - d) It's only useful for startups
   **Answer**: b

2. **Multiple choice**: Which canvas section maps most directly to IS/DOES/MEANS?
   - a) Cost Structure → IS, Revenue → DOES, Channels → MEANS
   - b) Solution → IS, Unique Value Proposition → DOES/MEANS, Problem → context
   - c) Key Metrics → IS, Unfair Advantage → MEANS
   - d) They don't map at all
   **Answer**: b

### Recap

- Lean Canvas captures your business hypothesis on one page
- 9 sections force clarity about problem, solution, and differentiation
- `lean-canvas-authoring` for new canvases, `lean-canvas-refinement` for iterative improvement
- The canvas feeds into portfolio messaging via `portfolio-canvas` entity extraction
- Start with Problem → Customer Segments → UVP, then fill in the rest

---

## Module 2: The IS/DOES/MEANS Framework

### Theory (3 min)

**cogni-portfolio** helps SMEs articulate their offerings using the
**IS/DOES/MEANS** messaging framework:

| Layer | Question | Scope | Example |
|-------|----------|-------|---------|
| **IS** (Features) | What is it? | Market-independent | "Cloud-based CRM platform" |
| **DOES** (Advantages) | What does it do? | Market-specific | "Automates B2B sales pipeline" |
| **MEANS** (Benefits) | What does it mean for me? | Customer-specific | "Close deals 40% faster" |

**Why this matters**:
- Features (IS) are universal — the product is what it is regardless of market
- Advantages (DOES) change by market — the same feature solves different problems
- Benefits (MEANS) change by customer — the same advantage means different things

**The common mistake**: Most companies lead with features (IS). Effective messaging
leads with benefits (MEANS) and works backward. cogni-portfolio ensures all three
layers are articulated and properly ordered for each target market.

### Demo

Walk through the IS/DOES/MEANS framework:
1. Pick a simple product (e.g., a project management tool)
2. Define IS: features that are true regardless of market
3. Define DOES for two different markets (consulting vs. manufacturing)
4. Define MEANS for specific customer personas in each market
5. Show how the messaging changes while the product stays the same

### Exercise

Ask the user to:
1. Pick a product or service they know well (their own or a client's)
2. Write 3 IS statements (market-independent features)
3. Pick one target market and write 2 DOES statements (market-specific advantages)
4. Write 1 MEANS statement (customer-specific benefit)

Create `_teacher-exercises/portfolio-draft.md` with a template:

```markdown
# Portfolio Messaging Draft

## Product/Service: [Name]

## IS (Features — market-independent)
1.
2.
3.

## DOES (Advantages — for market: [specify])
1.
2.

## MEANS (Benefits — for customer: [specify])
1.
```

### Quiz

1. **Multiple choice**: Which layer of IS/DOES/MEANS is market-independent?
   - a) DOES (Advantages)
   - b) MEANS (Benefits)
   - c) IS (Features)
   - d) All of them
   **Answer**: c

2. **Multiple choice**: Effective messaging should lead with:
   - a) Features (IS) — what it is
   - b) Benefits (MEANS) — what it means for the customer
   - c) Advantages (DOES) — what it does
   - d) Price
   **Answer**: b

### Recap

- IS = features (market-independent)
- DOES = advantages (market-specific)
- MEANS = benefits (customer-specific)
- Lead with MEANS, support with DOES, back with IS

---

## Module 3: Market Targeting — TAM/SAM/SOM

### Theory (3 min)

Before messaging, define your market. cogni-portfolio uses the
**TAM/SAM/SOM** framework:

| Level | Definition | Example |
|-------|-----------|---------|
| **TAM** (Total Addressable Market) | Everyone who could use this | "All companies needing CRM" |
| **SAM** (Serviceable Addressable Market) | Who you can realistically reach | "B2B mid-market in DACH region" |
| **SOM** (Serviceable Obtainable Market) | Who you'll actually win | "Manufacturing SMEs in Bavaria" |

**Why this matters for messaging**:
- TAM helps validate the opportunity exists
- SAM defines where your DOES (advantages) apply
- SOM defines where your MEANS (benefits) resonate

**cogni-portfolio links targeting to messaging**:
- Each SOM segment gets its own DOES/MEANS messaging
- Competitor analysis identifies differentiation per segment
- Customer analysis reveals which benefits matter most

### Demo

Walk through TAM/SAM/SOM:
1. Take the product from Module 1
2. Define TAM broadly
3. Narrow to SAM with geographic/industry/size filters
4. Define SOM — the beachhead market
5. Show how messaging sharpens from TAM to SOM

### Exercise

Ask the user to:
1. Take their product from Module 1
2. Define TAM: Who could theoretically use this?
3. Define SAM: Who can you realistically serve?
4. Define SOM: Who will you win first?
5. Link back: How does the MEANS statement change for SOM vs. SAM?

### Quiz

1. **Multiple choice**: What's the difference between SAM and SOM?
   - a) SAM is bigger than SOM
   - b) SAM = who you can reach; SOM = who you'll actually win
   - c) They're the same thing
   - d) SAM is for B2B, SOM is for B2C
   **Answer**: b

2. **Hands-on**: Define your SOM in one sentence.

### Recap

- TAM → SAM → SOM narrows from opportunity to target
- Each level sharpens your messaging
- SOM = your beachhead market with most specific benefits
- Targeting drives everything in portfolio messaging

---

## Module 4: Competitor & Customer Analysis

### Theory (3 min)

Two analyses feed into portfolio messaging:

**Competitor analysis** answers: "Why choose us over them?"
- Identify key competitors in your SOM
- Map their IS/DOES/MEANS positioning
- Find gaps — advantages they don't offer
- Find parity — table-stakes features you must match

**Customer analysis** answers: "What do they actually care about?"
- Customer pain points and jobs-to-be-done
- Decision criteria and buying process
- Value drivers — what moves the needle
- Objections — what holds them back

**How this feeds messaging**:
- Competitive gaps → your differentiation (unique DOES)
- Customer pain points → your benefits (specific MEANS)
- Decision criteria → your proof points
- Objections → your counter-messaging

### Demo

Walk through analysis:
1. Pick 2 competitors for the sample product
2. Map their positioning on IS/DOES/MEANS
3. Identify one competitive gap
4. Define one customer pain point that gap addresses
5. Write messaging that connects gap → pain → benefit

### Exercise

Ask the user to:
1. Name 2 competitors for their product
2. For each: What do they lead with? (IS, DOES, or MEANS?)
3. Identify one thing your product does that they don't
4. Identify one customer pain point this uniquely solves

### Quiz

1. **Multiple choice**: What should competitor analysis reveal?
   - a) Their revenue and employee count
   - b) Positioning gaps and table-stakes parity
   - c) Their customer list
   - d) Their pricing strategy
   **Answer**: b

2. **Open-ended**: Name one competitive advantage that directly addresses a customer pain point.

### Recap

- Competitor analysis finds gaps and parity
- Customer analysis finds pains and value drivers
- Together they sharpen DOES/MEANS messaging
- Differentiation = your unique gap + their real pain

---

## Module 5: Building Propositions

### Theory (3 min)

A **proposition** combines IS/DOES/MEANS with targeting and analysis into
a customer-ready message:

**Proposition structure**:
```
For [SOM segment] who [pain point],
[Product] is a [IS category] that [DOES advantage].
Unlike [competitor], we [unique MEANS benefit].
```

cogni-portfolio builds propositions for each SOM segment:
1. Start with the segment definition
2. Apply relevant IS features
3. Add market-specific DOES advantages
4. Lead with customer-specific MEANS benefits
5. Differentiate against identified competitors

**Multiple propositions per product**: The same product needs different
propositions for different segments, channels, and use cases.

### Demo

Walk through building a proposition:
1. Use the work from Modules 1-3 (product, targeting, analysis)
2. Fill in the proposition template
3. Create a second proposition for a different segment
4. Compare: same product, different messaging
5. Discuss where each proposition would be used (website, pitch, email)

### Exercise

Ask the user to:
1. Write a proposition using the template:
   ```
   For [their SOM] who [key pain point],
   [their product] is a [category] that [top advantage].
   Unlike [competitor], we [unique benefit].
   ```
2. Write a second proposition for a different segment or use case
3. Share both and discuss which is stronger

### Quiz

1. **Hands-on**: Read your proposition aloud. Does it pass the "so what?" test?

2. **Multiple choice**: Why do you need multiple propositions for one product?
   - a) Different segments have different pains and value different benefits
   - b) To fill more slides in a presentation
   - c) Because one proposition isn't enough words
   - d) For SEO purposes
   **Answer**: a

### Recap

- Propositions combine IS/DOES/MEANS + targeting + differentiation
- Template: For [who] with [pain], we [advantage], unlike [them], we [benefit]
- Same product → different propositions per segment
- Lead with benefits, support with advantages, prove with features

---

## Module 6: Portfolio Strategy & Cross-Plugin Flow

### Theory (3 min)

**Portfolio strategy** ties everything together:
- Multiple products/services in a coherent portfolio
- Consistent messaging framework across all offerings
- Clear segmentation showing which offering serves which market

**cogni-portfolio outputs**:
- IS/DOES/MEANS matrix per product
- TAM/SAM/SOM sizing per segment
- Competitor positioning maps
- Proposition statements per segment
- Portfolio overview document

**Cross-plugin integration**:
1. Portfolio propositions → **cogni-copywriting** (polish messaging)
2. Portfolio strategy → **cogni-narrative** (executive narrative with corporate-visions arc)
3. Claims in analysis → **cogni-claims** (verify market data)
4. Portfolio overview → **cogni-visual** (presentation, one-pager)
5. Market trends → **cogni-trends** (validate with trend data)

### Demo

Walk through the full portfolio workflow:
1. Show a complete IS/DOES/MEANS matrix
2. Show how it maps to target segments
3. Demonstrate polishing a proposition with `/copywrite`
4. Show how a portfolio narrative would use the corporate-visions arc
5. Preview how Course 7 (Visual) would turn this into a pitch deck

### Exercise

Ask the user to:
1. Review their work from this course: IS/DOES/MEANS, TAM/SAM/SOM, propositions
2. Identify: which proposition would benefit from copywriting polish?
3. Which market data claims should be verified?
4. Draft a brief portfolio summary (3-5 sentences covering their full offering)

### Quiz

1. **Multiple choice**: Which narrative arc best fits a portfolio pitch?
   - a) Trend Panorama
   - b) Corporate Visions (Why Change → Why Now → Why You → Why Pay)
   - c) Strategic Foresight
   - d) Industry Transformation
   **Answer**: b

2. **Open-ended**: Describe one cross-plugin workflow you'd use for your portfolio work.

### Recap

- Portfolio strategy = consistent messaging across all offerings
- IS/DOES/MEANS matrix shows the full picture
- Cross-plugin flow: portfolio → copywrite → narrative → visual
- Your expertise shapes the strategy; tools execute the deliverables

---

## Course Completion

Congratulations! You now know how to:
- Start with a Lean Canvas hypothesis (cogni-consulting business-model-hypothesis)
- Apply IS/DOES/MEANS messaging framework (cogni-portfolio)
- Define markets with TAM/SAM/SOM
- Conduct competitor and customer analysis for messaging
- Build segment-specific propositions
- Connect portfolio work with other insight-wave plugins

**Something unclear or broken?** Tell Claude what happened — cogni-issues will help you file it.

**Next recommended course**: Course 7 — Visual Deliverables
