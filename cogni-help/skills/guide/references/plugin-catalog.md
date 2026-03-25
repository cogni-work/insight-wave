# insight-wave Plugin Catalog

Curated reference for the guide skill. Each entry covers what the plugin does, its key
skills/commands, and when to recommend it.

---

## cogni-claims

**Purpose**: Claim verification against cited sources. Detects deviations between what
a document claims and what the source actually says.

**Key commands**: `/verify-claims`

**Use when**: User has a document with sourced claims that need fact-checking, or wants
to verify research output before publishing.

**Works with**: cogni-research (verifies research claims), cogni-narrative (checks narrative accuracy)

---

## cogni-consulting

**Purpose**: Double Diamond consulting orchestrator. Guides engagements through Discover,
Define, Develop, Deliver phases by dispatching to other insight-wave plugins. Also includes
Lean Canvas authoring and refinement via the business-model-hypothesis vision class.

**Key commands**: `/consulting-setup`, `/consulting-discover`, `/consulting-define`,
`/consulting-develop`, `/consulting-deliver`

**Use when**: User is running a structured consulting engagement and wants phase-gated
orchestration that calls the right plugins at the right time.

**Requires**: Most other plugins (it orchestrates them)

---

## cogni-copywriting

**Purpose**: Document polishing with messaging frameworks (BLUF, Pyramid, SCQA, STAR,
PSB, FAB). Stakeholder review via parallel persona Q&A. Readability optimization.

**Key commands**: `/polish`, `/review`, `/readability`

**Use when**: User has a rough draft and needs professional polish, wants stakeholder
perspective simulation, or needs readability scoring.

**Works with**: cogni-narrative (narrative → polish), cogni-sales (pitch polish)

---

## cogni-help (this plugin)

**Purpose**: Central help hub — courses, plugin discovery, workflows, troubleshooting,
cheatsheets, and issue filing.

**Key commands**: `/teach`, `/courses`, `/guide`, `/workflow`, `/troubleshoot`,
`/cheatsheet`, `/issues`

**Use when**: User is learning the ecosystem, needs to find the right plugin, wants
workflow guidance, or needs to file a bug/feature request.

---

## cogni-marketing

**Purpose**: B2B marketing content engine. Bridges TIPS themes and portfolio propositions
into channel-ready content (thought leadership, demand gen, lead gen, sales enablement, ABM).

**Key commands**: `/marketing-brief`, `/marketing-content`, `/marketing-campaign`

**Use when**: User needs marketing materials that connect strategic trends to portfolio
propositions. Supports 16 content formats. Bilingual DE/EN.

**Requires**: cogni-trends (themes), cogni-portfolio (propositions)

---

## cogni-narrative

**Purpose**: Story arc-driven narrative transformation. 7 narrative frameworks including
TIPS-native trend panorama. Executive synthesis and citation bridging.

**Key commands**: `/narrate`, `/review-narrative`

**Use when**: User has structured content (research output, data) and needs it transformed
into a compelling executive narrative or story.

**Feeds into**: cogni-visual (narrative → slides), cogni-copywriting (narrative → polish)

---

## cogni-obsidian

**Purpose**: Obsidian vault integration. Scaffolds vaults with Terminal plugin, manages
frontmatter, provides note management for insight-wave workplaces.

**Key commands**: `/init-vault`

**Use when**: User wants to set up an Obsidian-based workplace for persistent, browsable
knowledge management alongside insight-wave plugins.

**Works with**: cogni-workspace (workspace → vault)

---

## cogni-portfolio

**Purpose**: Portfolio messaging using IS/DOES/MEANS framework. Market-independent features
(IS), market-specific advantages (DOES) and benefits (MEANS). TAM/SAM/SOM, competitors.

**Key commands**: `/portfolio-setup`, `/portfolio-draft`, `/portfolio-export`

**Use when**: User needs to define product/service propositions, map them to markets,
size the opportunity, or analyze competitors.

**Requires**: cogni-consulting (optional, for Lean Canvas hypothesis input)
**Feeds into**: cogni-marketing (propositions → content), cogni-sales (propositions → pitch)

---

## cogni-research

**Purpose**: Multi-agent research report generator. STORM-inspired editorial workflow
with parallel web research, claims-verified review loops. Three depth levels.

**Key commands**: `/research`

**Use when**: User needs a researched report on a topic — from quick summaries to
deep-dive analyses with verified claims and citations.

**Works with**: cogni-claims (verification), cogni-narrative (report → story)

---

## cogni-sales

**Purpose**: B2B sales pitch generation using Corporate Visions Why Change methodology.
Named-customer pitches or reusable segment pitches. Bilingual DE/EN.

**Key commands**: `/pitch-setup`, `/pitch-draft`

**Use when**: User needs a sales presentation or proposal for a specific customer or
market segment, built on portfolio data with optional trend enrichment.

**Requires**: cogni-portfolio (propositions), optionally cogni-trends (strategic trends)

---

## cogni-trends

**Purpose**: Strategic trend scouting and reporting. Combines Smarter Service Trendradar
(4 dimensions) with TIPS framework (Trends, Implications, Possibilities, Solutions).

**Key commands**: `/scout`, `/report`, `/tips-status`

**Use when**: User needs to identify industry trends, analyze their implications, or
produce trend reports for strategic decision-making. DACH-focused. Bilingual EN/DE.

**Feeds into**: cogni-portfolio (trends → investment themes), cogni-marketing (themes → content)

---

## cogni-visual

**Purpose**: Transform narratives into visual deliverables — slide decks, big-picture
journey maps, Big Block architectures, web narratives, poster storyboards.

**Key commands**: `/render-slides`, `/render-big-picture`, `/render-web-narrative`

**Use when**: User has polished narrative content and needs visual output. Supports
Excalidraw, Pencil MCP, and PPTX rendering.

**Requires**: Content from cogni-narrative or cogni-copywriting as input

---

## cogni-workspace

**Purpose**: Lean workspace orchestrator. Manages shared foundation (env vars, settings),
theme management, plugin discovery, and workspace health diagnostics.

**Key commands**: `/init-workspace`, `/workspace-status`, `/pick-theme`, `/manage-themes`

**Use when**: User needs to initialize or maintain their insight-wave workspace, manage
themes, or diagnose workspace configuration issues.

**Foundation for**: All other plugins (provides shared env vars and settings)
