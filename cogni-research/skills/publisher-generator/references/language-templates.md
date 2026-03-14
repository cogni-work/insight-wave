# Language Templates

Localized header strings for publisher entity generation based on `--language` parameter.

## Language Detection

1. If `--language` provided: Validate ISO 639-1 format (2-letter lowercase), must be `en` or `de`
2. If not provided: Detect from project metadata (`.metadata/project-config.json`)
3. Fallback: Sample 3 source files for majority language
4. Default: `en`

## Supported Languages

### English (en)

| Variable | Value |
|----------|-------|
| `HEADER_CONTEXT` | Context |
| `HEADER_TYPE` | Type |
| `HEADER_SOURCES` | Related Sources |
| `HEADER_MISSION` | Mission & Mandate |
| `HEADER_ESTABLISHMENT` | Establishment & Headquarters |
| `HEADER_EXPERTISE` | Domain Expertise |
| `HEADER_CREDIBILITY` | Credibility Assessment |
| `HEADER_BACKGROUND` | Professional Background |
| `HEADER_EXPERTISE_ROLE` | Expertise & Role |
| `HEADER_POSITIONS` | Key Positions |
| `NOT_DOCUMENTED` | Not publicly documented |
| `LANGUAGE_NAME` | English |

### German (de)

| Variable | Value |
|----------|-------|
| `HEADER_CONTEXT` | Kontext |
| `HEADER_TYPE` | Typ |
| `HEADER_SOURCES` | Zugehörige Quellen |
| `HEADER_MISSION` | Mission & Mandat |
| `HEADER_ESTABLISHMENT` | Gründung & Hauptsitz |
| `HEADER_EXPERTISE` | Domänenexpertise |
| `HEADER_CREDIBILITY` | Glaubwürdigkeitsbewertung |
| `HEADER_BACKGROUND` | Beruflicher Hintergrund |
| `HEADER_EXPERTISE_ROLE` | Expertise & Rolle |
| `HEADER_POSITIONS` | Schlüsselpositionen |
| `NOT_DOCUMENTED` | Nicht öffentlich dokumentiert |
| `LANGUAGE_NAME` | German |

## Usage in Entity Generation

**Frontmatter:**
```yaml
language: {LANGUAGE}
```

**Body headers:**
```markdown
**{HEADER_TYPE}:** {pub_type}

## {HEADER_SOURCES}

## {HEADER_CONTEXT}

### {HEADER_MISSION}  # organizations
### {HEADER_BACKGROUND}  # individuals
```

## Web Search Query Templates

**Individuals (non-English):**
```
"{pub_name}" expertise background role (in {LANGUAGE_NAME})
```

**Organizations (non-English):**
```
"{pub_name}" mission mandate headquarters expertise (in {LANGUAGE_NAME})
```

## Error Response

Invalid language code returns:
```json
{
  "success": false,
  "error": "Invalid language code 'fr'. Supported: en, de (ISO 639-1 format)",
  ...
}
```
