# Course 4: Trend Scouting & Selection (TIPS Part 1)

**Duration**: 45 minutes | **Modules**: 5 | **Prerequisites**: Course 3
**Plugin**: cogni-tips
**Audience**: Consultants conducting strategic trend research

---

## Module 1: The TIPS Framework

### Theory (3 min)

**TIPS** stands for Trends, Implications, Possibilities, Solutions — a structured
framework for analyzing trends beyond surface-level observation.

| Element | Question | Example |
|---------|----------|---------|
| **Trend** | What is happening? | "AI agents automating knowledge work" |
| **Implications** | So what? What does it mean? | "Mid-level analyst roles will transform" |
| **Possibilities** | What could we do? | "Retrain analysts as AI supervisors" |
| **Solutions** | What should we do now? | "Launch pilot AI-augmented team in Q2" |

**Why TIPS matters for consultants**: Clients don't just want to know what trends
exist — they want to know what it means for their business and what to do about it.
TIPS provides that complete analytical arc.

### Demo

Walk through a TIPS example:
1. Pick a trend the user's industry cares about
2. Expand it through T → I → P → S
3. Show how each layer adds strategic depth
4. Compare: raw trend observation vs. full TIPS analysis

### Exercise

Ask the user to:
1. Name one trend affecting their industry or their clients
2. Manually expand it through TIPS:
   - T: State the trend in one sentence
   - I: What are 2-3 implications?
   - P: What possibilities does this create?
   - S: What concrete action should be taken?

### Quiz

1. **Multiple choice**: What does the "I" in TIPS stand for?
   - a) Innovation
   - b) Implications
   - c) Integration
   - d) Intelligence
   **Answer**: b

2. **Open-ended**: Why is "So what?" (Implications) the most important question in consulting?

### Recap

- TIPS = Trends, Implications, Possibilities, Solutions
- Moves from observation → meaning → options → action
- The "so what?" chain clients pay for
- Foundation for the entire cogni-tips pipeline

---

## Module 2: The Smarter Service Trendradar

### Theory (3 min)

cogni-tips structures trends using the **Smarter Service Trendradar** — a
four-dimension model that ensures comprehensive coverage:

| Dimension (DE) | Dimension (EN) | What It Covers |
|----------------|----------------|----------------|
| Externe Effekte | External Forces | Regulation, economy, society, environment |
| Neue Horizonte | Strategic New Horizons | New business models, markets, opportunities |
| Digitale Wertetreiber | Digital Value Drivers | AI, automation, data, customer experience |
| Digitales Fundament | Digital Foundation | Infrastructure, security, architecture |

**Three time horizons**:
| Horizon | Timeframe | Action |
|---------|-----------|--------|
| Act | 0-2 years | Implement now |
| Plan | 2-5 years | Prepare strategy |
| Observe | 5+ years | Monitor signals |

Together: 4 dimensions x 3 horizons = comprehensive trend landscape.

**Bilingual support**: The pipeline works in both English and German, crucial
for DACH market consulting.

### Demo

Walk through the Trendradar structure:
1. Visualize the 4 dimensions as quadrants
2. Show how trends distribute across horizons
3. Explain why "External Forces" matters even for tech-focused projects
4. Show a sample Trendradar output with trends placed in quadrants

### Exercise

Ask the user to:
1. Think of their client's industry
2. Name one trend for each dimension:
   - External Forces: (regulation, macro trend)
   - Strategic New Horizons: (new opportunity)
   - Digital Value Drivers: (tech-driven value)
   - Digital Foundation: (infrastructure need)

### Quiz

1. **Multiple choice**: How many dimensions does the Trendradar have?
   - a) 3
   - b) 4
   - c) 5
   - d) 6
   **Answer**: b

2. **Multiple choice**: A trend with "Act" horizon means:
   - a) Observe for now, no action needed
   - b) Plan strategy for 2-5 years out
   - c) Implement now, within 0-2 years
   - d) It's already obsolete
   **Answer**: c

### Recap

- 4 dimensions ensure comprehensive trend coverage
- 3 horizons prioritize by urgency (Act/Plan/Observe)
- Bilingual (EN/DE) for DACH market work
- Structure ensures no blind spots in trend analysis

---

## Module 3: Starting a Trend Scout

### Theory (3 min)

The **trend-scout** skill orchestrates the full scouting pipeline. The process:

1. **Industry selection** — Interactive: choose or describe the target industry
2. **Web research** — 32 bilingual searches (EN + DE) across:
   - General web
   - Academic sources
   - Patent databases
   - Regulatory sources
3. **Signal aggregation** — Research results compiled into structured signals
4. **Trend generation** — AI synthesizes 60 scored trend candidates

**Scoring frameworks** applied to each candidate:
- **Ansoff signal intensity** — How strong is the evidence?
- **Rogers diffusion stage** — Where on the adoption curve?
- **CRAAP source quality** — How reliable are the sources?

The scout delegates work to specialized sub-agents:
- `trend-web-researcher` — Executes the 32 searches in parallel
- `trend-generator` — Synthesizes candidates from research signals

### Demo

Walk through starting a trend scout:
1. Explain the prompt: "Scout trends for [industry]"
2. Show the industry selection interaction
3. Explain what happens during the 32-search phase
4. Show sample research signals and how they feed into generation

(Note: A full scout takes significant time. Show the process conceptually
and use sample outputs for demonstration.)

### Exercise

Ask the user to:
1. Choose an industry for scouting (their client's or their own interest)
2. Start a trend scout: "Scout trends for [their chosen industry]"
3. Observe the industry selection interaction
4. Note: the full scout will run in the background — continue the course while it works

### Quiz

1. **Multiple choice**: How many web searches does trend-scout execute?
   - a) 10
   - b) 16
   - c) 32
   - d) 64
   **Answer**: c

2. **Multiple choice**: Which scoring framework measures source reliability?
   - a) Ansoff
   - b) Rogers
   - c) CRAAP
   - d) TIPS
   **Answer**: c

### Recap

- Trend scout = automated research pipeline
- 32 bilingual searches across web, academic, patent, regulatory
- Three scoring frameworks rate each candidate
- Specialized sub-agents handle research and generation

---

## Module 4: Reviewing Scored Candidates

### Theory (3 min)

The trend-scout skill generates 60 scored candidates that are automatically
finalized for downstream reporting. While all 60 candidates proceed, reviewing
them builds your understanding of the trend landscape.

**What to look for when reviewing**:
- **Relevance**: Does this trend matter for the specific client/industry?
- **Evidence strength**: Are the Ansoff/Rogers/CRAAP scores solid?
- **Balance**: Are all 4 dimensions and 3 horizons represented?
- **Source mix**: Is there a healthy balance of web-sourced vs. training-sourced candidates?

**The consultant's judgment matters**: While all 60 candidates proceed to
reporting, understanding them helps you contextualize the final report for
your client. This is where your expertise adds the most value.

### Demo

Walk through the candidate review:
1. Show a batch of trend candidates for one dimension
2. Walk through evaluating 3-4 candidates:
   - Check scores, read TIPS expansion
   - Assess source quality and signal intensity
3. Show how candidates distribute across horizons
4. Explain the scoring frameworks (Ansoff, Rogers, CRAAP)

### Exercise

If the trend scout from Module 3 has produced candidates:
1. Review the first batch of candidates together
2. Identify the 3 strongest and 3 weakest candidates by score
3. Discuss what makes a candidate strong or weak

If the scout is still running:
1. Use sample candidate data to practice evaluation
2. Rate 3 sample candidates based on their scores and TIPS expansion

### Quiz

1. **Multiple choice**: How many trend candidates does trend-scout generate?
   - a) 10
   - b) 25
   - c) 60
   - d) 100
   **Answer**: c

2. **Open-ended**: Why is reviewing candidates important even though all 60 proceed to reporting?

### Recap

- Trend-scout generates 60 scored candidates across the Trendradar
- All 60 candidates are finalized for downstream reporting
- Reviewing builds understanding for client contextualization
- Scored candidates feed into the reporting phase (Course 5)

---

## Module 5: Understanding the Full Pipeline

### Theory (3 min)

The complete cogni-tips pipeline spans two courses:

**Course 4 (this course)**:
```
Industry → Web Research (32 searches) → Signal Aggregation →
60 Scored Candidates → Auto-Finalized for Reporting
```

**Course 5 (next course)**:
```
Agreed Trends → Evidence Enrichment → Narrative Report →
Claims Extraction → Verification → Final Report
```

**Key integration points**:
- Selected trends → cogni-narrative (trend-panorama arc)
- Report claims → cogni-claims (verification)
- Final report → cogni-copywriting (polishing)
- Report content → cogni-visual (presentations)

**Time investment**: A full trend scouting cycle takes significant Cowork time
(research phase can run 30+ minutes). Plan accordingly:
- Start the scout early, let it run while doing other work
- Review candidates to build understanding of the trend landscape
- Reporting is covered in Course 5

### Demo

Walk through the pipeline visually:
1. Draw the end-to-end flow
2. Map each stage to the cogni-tips skill that handles it
3. Show integration points with other cogni-works plugins
4. Discuss time estimates for each phase

### Exercise

Ask the user to:
1. Review their trend scout progress (if still running)
2. Map the pipeline to their current consulting workflow:
   - How do they currently do trend research?
   - Which phases would save the most time?
   - Where does their expertise add most value?

### Quiz

1. **Hands-on**: Draw or describe the full TIPS pipeline from industry selection to final report.

2. **Multiple choice**: What feeds into the trend-report phase (Course 5)?
   - a) Raw web search results
   - b) All 60 scored trend candidates
   - c) Only high-confidence candidates
   - d) Only "Act" horizon trends
   **Answer**: b

### Recap

- Full pipeline: Scout → Report → Verify
- Integration with narrative, claims, copywriting, visual
- Research runs autonomously; review builds understanding
- Course 5 covers the reporting and verification phases

---

## Course Completion

Congratulations! You now understand:
- The TIPS framework (Trends → Implications → Possibilities → Solutions)
- The Smarter Service Trendradar (4 dimensions, 3 horizons)
- How to launch and monitor a trend scout
- How to review scored candidates for client context
- The full pipeline and where your expertise fits

**Next recommended course**: Course 5 — Trend Reporting
