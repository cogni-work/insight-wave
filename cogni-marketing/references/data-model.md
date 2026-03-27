# cogni-marketing Data Model

## Project Structure

```
cogni-marketing/{project-slug}/
├── marketing-project.json          # Root manifest
├── content-strategy.json           # Content matrix (market × GTM path × content type)
├── content/
│   ├── thought-leadership/
│   │   └── {market}--{gtm-path}--{format}.md
│   ├── demand-generation/
│   │   └── {market}--{gtm-path}--{format}.md
│   ├── lead-generation/
│   │   └── {market}--{gtm-path}--{format}.md
│   ├── sales-enablement/
│   │   └── {market}--{gtm-path}--{format}.md
│   └── abm/
│       └── {market}--{account}--{format}.md
├── campaigns/
│   └── {market}--{gtm-path}--{campaign-name}.json
├── calendar/
│   ├── content-calendar.yaml       # Source of truth
│   └── content-calendar.md         # Rendered view
├── output/
│   ├── dashboard.html              # Interactive dashboard
│   └── exports/                    # CSV, briefs, etc.
└── .logs/
    └── seo-research-{market}.json  # SEO researcher output
```

## marketing-project.json Schema

```json
{
  "slug": "string (kebab-case, e.g. acme-cloud-marketing)",
  "name": "string (display name)",
  "language": "de|en",
  "created": "ISO-8601",
  "updated": "ISO-8601",

  "sources": {
    "tips_project": "relative path to cogni-trends project",
    "portfolio_project": "relative path to cogni-portfolio project",
    "enriched_portfolio_narratives": {
      "overview": "relative path to customer-narrative/portfolio-overview.md (or null)",
      "markets": { "{market-slug}": "relative path to market narrative (or null)" },
      "personas": { "{market-slug}--{persona}": "relative path to persona narrative (or null)" }
    }
  },

  "brand": {
    "name": "string (company/brand name)",
    "voice": "string (e.g. 'authoritative, approachable, data-driven')",
    "tone_modifiers": {
      "whitepaper": "+formal, +detailed",
      "social": "+conversational, +punchy",
      "email": "+personal, +direct",
      "blog": "+educational, +engaging",
      "battle-card": "+competitive, +factual"
    },
    "cta_style": "soft-ask|direct|value-exchange",
    "visual_direction": "string (e.g. 'minimal, blue/dark palette, data-vis focus')"
  },

  "markets": [
    {
      "slug": "string (from portfolio market slug)",
      "priority": "primary|secondary",
      "gtm_paths": [
        {
          "theme_id": "string (TIPS strategic theme ID)",
          "theme_name": "string",
          "priority": 1,
          "funnel_focus": "awareness|consideration|decision|full-funnel"
        }
      ]
    }
  ],

  "content_defaults": {
    "blog": { "words": 1000, "evidence": true },
    "linkedin-article": { "words": 800, "evidence": true },
    "linkedin-post": { "words": 250, "evidence": false },
    "whitepaper": { "words": 3000, "evidence": true },
    "email-nurture": { "words": 200, "evidence": false },
    "landing-page": { "words": 400, "evidence": false },
    "battle-card": { "words": 500, "evidence": true },
    "one-pager": { "words": 600, "evidence": true },
    "webinar-outline": { "words": 800, "evidence": true },
    "carousel": { "slides": 8, "words_per_slide": 30 },
    "video-script": { "duration_seconds": 90, "words": 225 },
    "keynote-abstract": { "words": 200, "evidence": false },
    "podcast-outline": { "words": 500, "evidence": false },
    "demo-script": { "words": 600, "evidence": false },
    "objection-handler": { "words": 400, "evidence": true },
    "account-plan": { "words": 1000, "evidence": true },
    "executive-briefing": { "words": 500, "evidence": true }
  },

  "calendar": {
    "cadence": {
      "linkedin-post": "3x/week",
      "blog": "2x/month",
      "email-nurture": "2x/month",
      "webinar": "1x/quarter",
      "whitepaper": "1x/quarter"
    }
  }
}
```

## content-strategy.json Schema

```json
{
  "version": "1.0",
  "created": "ISO-8601",
  "updated": "ISO-8601",

  "funnel_model": {
    "stages": ["awareness", "consideration", "decision"],
    "content_type_mapping": {
      "thought-leadership": ["awareness"],
      "demand-generation": ["awareness", "consideration"],
      "lead-generation": ["consideration"],
      "sales-enablement": ["decision"],
      "abm": ["awareness", "consideration", "decision"]
    }
  },

  "matrix": {
    "{market-slug}": {
      "{gtm-path-theme-id}": {
        "theme_name": "string",
        "narrative_angle": "string (WHY NOW from TIPS value chain)",
        "portfolio_propositions": ["feat--mkt slug", "..."],
        "content_plan": {
          "thought-leadership": {
            "formats": ["blog", "linkedin-article", "keynote-abstract"],
            "status": "planned|in-progress|complete",
            "pieces_planned": 3,
            "pieces_generated": 0
          },
          "demand-generation": { "..." },
          "lead-generation": { "..." },
          "sales-enablement": { "..." }
        }
      }
    }
  }
}
```

## Content Piece Frontmatter

Every generated content file uses YAML frontmatter:

```yaml
---
type: thought-leadership|demand-generation|lead-generation|sales-enablement|abm
format: blog|linkedin-post|whitepaper|email-nurture|...
market: market-slug
gtm_path: theme-id
funnel_stage: awareness|consideration|decision
language: de|en
brand_voice: "base voice + modifier"
sources:
  tips_theme: "theme name"
  tips_claims: ["claim_id_1", "claim_id_2"]
  portfolio_propositions: ["feat--mkt"]
  portfolio_competitors: ["feat--mkt"]
word_count: 850
status: draft|reviewed|published
created: ISO-8601
---
```

## Cross-Plugin References

- **cogni-trends**: `sources.tips_project` → reads `tips-value-model.json` for strategic themes, `trend-scout-output.json` for trend data, `tips-trend-report-claims.json` for evidence
- **cogni-portfolio**: `sources.portfolio_project` → reads `propositions/`, `competitors/`, `customers/`, `solutions/`, `packages/`, `portfolio.json`. Optionally reads `output/communicate/customer-narrative/` for pre-written audience-tailored narratives (via `sources.enriched_portfolio_narratives`)
- **cogni-copywriting**: Generated content can be piped to `copywriter` skill for polishing
- **cogni-narrative**: Long-form thought leadership can be piped to `narrative` skill for arc-driven transformation
- **cogni-visual**: Content briefs can be piped to `story-to-slides` or `canvas` for visual deliverables
- **cogni-claims**: Evidence claims in content inherit verification status from TIPS claims registry

## Naming Conventions

- **Project slug**: `{company}-marketing` or `{company}-{campaign}-marketing`
- **Content files**: `{market}--{gtm-path}--{format}.md` (double-dash separators, matching portfolio convention)
- **Campaign files**: `{market}--{gtm-path}--{campaign-name}.json`
- **ABM content**: `{market}--{account-slug}--{format}.md`
