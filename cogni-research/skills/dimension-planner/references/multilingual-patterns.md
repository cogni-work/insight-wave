## Section 5: Multilingual Support

**Reference:** See [../../../references/language-templates.md](../../../references/language-templates.md) for complete language template definitions.

### Language-Aware Section Headers

Section headers MUST match the project `language` field:

#### Research Dimensions (01-research-dimensions)

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Overview | Overview | Übersicht |
| Research Questions | Research Questions | Forschungsfragen |
| Key Themes | Key Themes | Kernthemen |
| Scope | Scope | Umfang |
| Boundaries | Boundaries | Abgrenzungen |
| Rationale | Rationale | Begründung |
| Research Focus | Research Focus | Forschungsschwerpunkt |

#### Refined Questions (02-refined-questions)

| Section | English (en) | German (de) |
|---------|--------------|-------------|
| Question | Question | Frage |
| Context | Context | Kontext |
| Scope | Scope | Umfang |
| Rationale | Rationale | Begründung |

### Language Detection & Project Language Loading

The dimension-planner supports multilingual research plans. Content generation adapts to project language while maintaining English technical identifiers for filesystem and semantic linking.

#### Language Detection Heuristics

```bash
# Simple language detection based on character sets
detect_language() {
  local content="$1"

  # Check for German umlauts
  if echo "$content" | grep -q '[äöüÄÖÜß]'; then
    echo "de"
    return
  fi

  # Check for French accents
  if echo "$content" | grep -q '[àâçéèêëîïôùûüÿæœ]'; then
    echo "fr"
    return
  fi

  # Check for Spanish accents
  if echo "$content" | grep -q '[áéíóúñ¿¡]'; then
    echo "es"
    return
  fi

  # Default to English
  echo "en"
}

# Usage in Phase 0
DETECTED_LANG=$(detect_language "$QUESTION_TEXT")
log_conditional INFO "Detected language: $DETECTED_LANG"
```

#### Project Language Initialization (Phase 0.4)

Project language drives all content generation. Load once at environment initialization:

```bash
# Phase 0.4: Load Project Language
# Read from .metadata/sprint-log.json
PROJECT_LANGUAGE=$(jq -r '.project_language // "en"' "$PROJECT_PATH/.metadata/sprint-log.json" 2>/dev/null || echo "en")

# Validate against supported languages
case "$PROJECT_LANGUAGE" in
  en|de|fr|es|it|pt|nl|ja|zh)
    log_conditional INFO "PROJECT_LANGUAGE=$PROJECT_LANGUAGE"
    ;;
  *)
    log_conditional WARNING "Unsupported language: $PROJECT_LANGUAGE, defaulting to en"
    PROJECT_LANGUAGE="en"
    ;;
esac

log_metric "project_language" "$PROJECT_LANGUAGE" "string"
```

**Fallback behavior:** If `.metadata/sprint-log.json` missing or language field empty, defaults to "en" (English).

### English Slug Generation Patterns

Dimension slugs always use English kebab-case, regardless of project language:

```bash
# Slug generation: Convert to English, then kebab-case
generate_english_slug() {
  local dimension_name="$1"

  # Translation map (extend as needed)
  case "$dimension_name" in
    "Kundenanalyse") echo "customer-analysis" ;;
    "Wirtschaftliche Analyse") echo "economic-analysis" ;;
    "Technische Machbarkeit") echo "technical-feasibility" ;;
    "Wettbewerbslandschaft") echo "competitive-landscape" ;;
    *)
      # Fallback: Convert to lowercase, remove special chars
      echo "$dimension_name" | tr '[:upper:]' '[:lower:]' | tr -cs 'a-z0-9' '-' | sed 's/^-\|-$//g'
      ;;
  esac
}

# Examples
SLUG=$(generate_english_slug "Kundenanalyse")  # → customer-analysis
SLUG=$(generate_english_slug "Problem Definition")  # → problem-definition
```

**Invariants:**
- Filesystem filenames use English slugs: `01-research-dimensions/data/dimension-customer-analysis.md`
- YAML keys always English: `dc:identifier: "customer-analysis"`
- Wikilink targets use English slugs: `[[01-research-dimensions/data/dimension-customer-analysis]]`

### Localized Display Name Generation

The `display_name` field in dimension entity frontmatter uses PROJECT_LANGUAGE:

```bash
# Phase 5.1: Generate localized display_name
generate_display_name() {
  local slug="$1"
  local language="$2"

  case "$language" in
    "de")
      case "$slug" in
        "customer-analysis") echo "Kundenanalyse" ;;
        "economic-analysis") echo "Wirtschaftliche Analyse" ;;
        "technical-feasibility") echo "Technische Machbarkeit" ;;
        "competitive-landscape") echo "Wettbewerbslandschaft" ;;
        *) echo "$(echo "$slug" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')" ;;
      esac
      ;;
    "fr")
      case "$slug" in
        "customer-analysis") echo "Analyse Clientèle" ;;
        "economic-analysis") echo "Analyse Économique" ;;
        "technical-feasibility") echo "Faisabilité Technique" ;;
        "competitive-landscape") echo "Paysage Concurrentiel" ;;
        *) echo "$(echo "$slug" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g')" ;;
      esac
      ;;
    "en"|*)
      # English: Titlecase slug
      echo "$slug" | sed 's/-/ /g' | sed 's/\b\(.\)/\u\1/g'
      ;;
  esac
}

# Usage in Phase 5.1
DISPLAY_NAME=$(generate_display_name "$SLUG" "$PROJECT_LANGUAGE")
```

**Frontmatter output (example - German project):**
```yaml
---
dc:identifier: "customer-analysis"
display_name: "Kundenanalyse"
language: "de"
---
```

### Content Localization: Rationale & Research Focus

Dimension rationale and research focus text are generated in PROJECT_LANGUAGE:

```bash
# Phase 5.1: Generate localized rationale
generate_dimension_rationale() {
  local slug="$1"
  local language="$2"

  if [ "$language" = "de" ]; then
    case "$slug" in
      "customer-analysis")
        echo "Diese Dimension untersucht die Zielkunden, ihre Bedürfnisse, Verhaltensweisen und Kaufmuster. Verständnis der Kundensegmentierung ist entscheidend für die Produktentwicklung und Marktstrategie."
        ;;
      "economic-analysis")
        echo "Analyse der wirtschaftlichen Viabilität, einschließlich Kostenschätzungen, Gewinnpotenzial und finanzieller Hindernisse. Untersucht Preisstrategie und wirtschaftliche Rentabilität."
        ;;
      *)
        echo "Diese Dimension behandelt die folgenden Aspekte: [generierte Beschreibung basierend auf Dimension und Kontext]"
        ;;
    esac
  else
    # English rationale
    case "$slug" in
      "customer-analysis")
        echo "This dimension investigates target customers, their needs, behaviors, and purchase patterns. Understanding customer segmentation is critical for product development and market strategy."
        ;;
      "economic-analysis")
        echo "Analysis of economic viability including cost estimates, profit potential, and financial barriers. Examines pricing strategy and economic sustainability."
        ;;
      *)
        echo "This dimension addresses the following aspects: [generated description based on dimension and context]"
        ;;
    esac
  fi
}

# Phase 5.1: Generate research focus (key topics in target language)
generate_research_focus() {
  local slug="$1"
  local language="$2"

  if [ "$language" = "de" ]; then
    case "$slug" in
      "customer-analysis")
        echo "Kundensegmente, Bedürfnisse und Schmerzpunkte, Käuferpersönlichkeiten, Marktgröße, Kundengewinnungsstrategie"
        ;;
      "economic-analysis")
        echo "Kostenstruktur, Preismodell, Umsatzströme, Gewinnmarge, Break-Even-Analyse, Finanzierungsbedarf"
        ;;
      *)
        echo "[Generierte Schlüsselthemen für diese Dimension]"
        ;;
    esac
  else
    # English research focus
    case "$slug" in
      "customer-analysis")
        echo "Customer segments, needs and pain points, buyer personas, market size, customer acquisition strategy"
        ;;
      "economic-analysis")
        echo "Cost structure, pricing model, revenue streams, profit margins, break-even analysis, funding needs"
        ;;
      *)
        echo "[Generated key topics for this dimension]"
        ;;
    esac
  fi
}
```

**Content sections in entity files (example - German project):**
```markdown
# Kundenanalyse






