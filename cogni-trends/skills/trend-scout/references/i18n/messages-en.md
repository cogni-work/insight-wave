# English Message Catalog for Trend Scout

Language: `en`

## Phase 0: Initialization

### Industry Selection Prompt

```text
INDUSTRY_SELECTION_TITLE: "Select Your Industry for Trend Scouting"
INDUSTRY_SELECTION_INTRO: "Please select your industry and subsector to begin trend scouting:"
INDUSTRY_SELECTION_PROMPT: "Enter your selection (e.g., '1a' for Manufacturing - Automotive):"
INDUSTRY_SELECTION_INVALID: "Invalid selection. Please enter a valid industry and subsector code (e.g., '1a')."
```

### Topic Prompt

```text
TOPIC_PROMPT_TITLE: "Research Topic"
TOPIC_PROMPT_INTRO: "What specific topic or focus area would you like to explore within {INDUSTRY} - {SUBSECTOR}?"
TOPIC_PROMPT_EXAMPLE: "Example: 'AI-driven predictive maintenance', 'Sustainable supply chain', 'Digital customer experience'"
TOPIC_PROMPT_ENTER: "Enter your research topic:"
```

### Portfolio Discovery

```text
PORTFOLIO_DISCOVERY_HEADER: "Portfolio Project Discovery"
PORTFOLIO_DISCOVERY_INTRO: "I found existing portfolio projects in your workspace. You can start trend-scouting directly for one of these markets — industry, subsector, and research focus will be pre-populated from your portfolio."
PORTFOLIO_DISCOVERY_PROJECT: "Portfolio: {COMPANY_NAME} ({INDUSTRY})"
PORTFOLIO_DISCOVERY_MARKET: "{MARKET_NAME} ({REGION}) — verticals: {VERTICALS} [alignment: {ALIGNMENT}]"
PORTFOLIO_DISCOVERY_SELECT: "Select a market to pre-populate, or choose 'Manual selection' to pick from the full industry taxonomy:"
PORTFOLIO_DISCOVERY_MANUAL: "Manual selection — use full industry taxonomy"
PORTFOLIO_DISCOVERY_NONE: "No portfolio projects found in workspace. Proceeding with manual industry selection."
PORTFOLIO_DISCOVERY_ASK_PATH: "I couldn't find any portfolio projects. Do you have a workspace directory with cogni-portfolio projects in a different location?"
PORTFOLIO_DISCOVERY_SELECTED: "Pre-populating from portfolio market: {MARKET_NAME}"
PORTFOLIO_DISCOVERY_TOPIC_SUGGEST: "Based on the selected market, a suggested research topic could be: '{TOPIC}'. Would you like to use this or enter your own?"
```

### Project Initialization

```text
PROJECT_INIT_START: "Initializing Trend Scout project..."
PROJECT_INIT_INDUSTRY: "Industry: {INDUSTRY}"
PROJECT_INIT_SUBSECTOR: "Subsector: {SUBSECTOR}"
PROJECT_INIT_TOPIC: "Topic: {TOPIC}"
PROJECT_INIT_SLUG: "Project slug: {SLUG}"
PROJECT_INIT_PATH: "Project path: {PATH}"
PROJECT_INIT_SUCCESS: "Project initialized successfully."
PROJECT_INIT_FAILED: "Project initialization failed: {ERROR}"
```

---

## Phase 1: Web Research

```text
WEB_RESEARCH_START: "Starting bilingual web research..."
WEB_RESEARCH_DIMENSION: "Searching {DIMENSION} ({REGION})..."
WEB_RESEARCH_PROGRESS: "Completed {COMPLETED}/{TOTAL} searches"
WEB_RESEARCH_SIGNALS: "Extracted {COUNT} trend signals from {DIMENSION}"
WEB_RESEARCH_SUCCESS: "Web research complete: {TOTAL} signals extracted across all dimensions"
WEB_RESEARCH_PARTIAL: "Web research partially complete: {SUCCESS}/{TOTAL} searches succeeded"
WEB_RESEARCH_FAILED: "Web research failed. Proceeding with training-only generation."
WEB_RESEARCH_DISABLED: "Web research disabled. Using training knowledge only."
```

---

## Phase 2: Candidate Generation

```text
GENERATION_START: "Generating trend candidates for {INDUSTRY} - {SUBSECTOR}..."
GENERATION_CONTEXT: "Using {WEB_COUNT} web signals and training knowledge"
GENERATION_PROGRESS: "Generating candidates for {DIMENSION} - {HORIZON}..."
GENERATION_COMPLETE: "Generated {TOTAL} candidates ({WEB_SOURCED} web-sourced, {TRAINING_SOURCED} training-sourced)"
```

---

## Phase 3: Presentation

```text
PRESENT_WRITING: "Writing trend-candidates.md..."
PRESENT_SUCCESS: "Candidate file written to: {PATH}"
PRESENT_COMPLETE: "All 60 candidates auto-finalized. Proceeding to finalization."
```

---

## Phase 4: Finalization

```text
FINALIZE_START: "Finalizing agreed candidates..."
FINALIZE_CONFIG: "Writing trend-scout-config.md..."
FINALIZE_JSON: "Writing agreed-trend-candidates.json..."
FINALIZE_UPDATE: "Updating trend-candidates.md status to 'agreed'..."
FINALIZE_SUCCESS_TITLE: "Trend Scout Complete"
FINALIZE_SUCCESS_SUMMARY: |
  Successfully finalized {COUNT} trend candidates.

  Output files:
  - Config: {CONFIG_PATH}
  - Candidates: {CANDIDATES_PATH}

  Next step: invoke `/value-modeler` to build TIPS relationship networks and ranked solution templates, or `/trend-report` for a direct narrative trend report.
  The configuration will be automatically loaded.
```

---

## Error Messages

```text
ERROR_NO_INDUSTRY: "Industry selection is required. Please select an industry and subsector."
ERROR_NO_TOPIC: "Research topic is required. Please provide a topic or focus area."
ERROR_PROJECT_EXISTS: "A project with this slug already exists. Use a different topic or delete the existing project."
ERROR_FILE_NOT_FOUND: "File not found: {PATH}"
ERROR_PARSE_FAILED: "Failed to parse {FILE}: {ERROR}"
ERROR_VALIDATION_FAILED: "Validation failed: {ERROR}"
```

---

## Dimension Names

```text
DIMENSION_EXTERNE_EFFEKTE: "External Effects"
DIMENSION_NEUE_HORIZONTE: "New Horizons"
DIMENSION_DIGITALE_WERTETREIBER: "Digital Value Drivers"
DIMENSION_DIGITALES_FUNDAMENT: "Digital Foundation"

HORIZON_ACT: "Act (0-2 years)"
HORIZON_PLAN: "Plan (2-5 years)"
HORIZON_OBSERVE: "Observe (5+ years)"
```

---

## Subcategory Names

```text
# Externe Effekte subcategories
SUBCATEGORY_WIRTSCHAFT: "Economy"
SUBCATEGORY_WIRTSCHAFT_FOCUS: "Market forces, competition, economic factors"
SUBCATEGORY_REGULIERUNG: "Regulation"
SUBCATEGORY_REGULIERUNG_FOCUS: "Policy, compliance, legal frameworks"
SUBCATEGORY_GESELLSCHAFT: "Society"
SUBCATEGORY_GESELLSCHAFT_FOCUS: "Demographics, societal shifts"

# Neue Horizonte subcategories
SUBCATEGORY_STRATEGIE: "Strategy"
SUBCATEGORY_STRATEGIE_FOCUS: "Business model direction, strategic goals"
SUBCATEGORY_FUEHRUNG: "Leadership"
SUBCATEGORY_FUEHRUNG_FOCUS: "Leadership approaches, organizational change"
SUBCATEGORY_STEUERUNG: "Governance"
SUBCATEGORY_STEUERUNG_FOCUS: "Governance, analytics, control systems"

# Digitale Wertetreiber subcategories
SUBCATEGORY_CUSTOMER_EXPERIENCE: "Customer Experience"
SUBCATEGORY_CUSTOMER_EXPERIENCE_FOCUS: "Customer touchpoints, engagement"
SUBCATEGORY_PRODUKTE_SERVICES: "Products & Services"
SUBCATEGORY_PRODUKTE_SERVICES_FOCUS: "Offerings, product innovation"
SUBCATEGORY_GESCHAEFTSPROZESSE: "Business Processes"
SUBCATEGORY_GESCHAEFTSPROZESSE_FOCUS: "Operations, process optimization"

# Digitales Fundament subcategories
SUBCATEGORY_KULTUR: "Culture"
SUBCATEGORY_KULTUR_FOCUS: "Organizational culture, mindset"
SUBCATEGORY_MITARBEITENDE: "Workforce"
SUBCATEGORY_MITARBEITENDE_FOCUS: "Workforce, skills, talent"
SUBCATEGORY_TECHNOLOGIE: "Technology"
SUBCATEGORY_TECHNOLOGIE_FOCUS: "Tech infrastructure, platforms"
```

---

## Table Headers

```text
TABLE_HEADER_SELECT: "Select"
TABLE_HEADER_NUMBER: "#"
TABLE_HEADER_NAME: "Name"
TABLE_HEADER_DESCRIPTION: "Description"
TABLE_HEADER_KEYWORDS: "Keywords"
TABLE_HEADER_RATIONALE: "Rationale"
TABLE_HEADER_MORE: "More?"
TABLE_HEADER_SOURCE: "Source"
```

---

## User Proposed Section

```text
USER_PROPOSED_TITLE: "User Proposed Candidates"
USER_PROPOSED_INSTRUCTIONS: |
  Add your own trend candidates below. Follow the format:

  | [x] | {dimension} | {horizon} | {name} | {description} | {keyword1}, {keyword2}, {keyword3} | {rationale} |

  Example:
  | [x] | externe-effekte | act | My Trend | Short description of the trend | keyword1, keyword2, keyword3 | Why this trend matters |
```
