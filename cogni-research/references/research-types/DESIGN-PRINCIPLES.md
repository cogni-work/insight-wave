# Research-Types Design Principles

## Core Principle: WHAT vs HOW Separation

### WHAT References (Master research-types)

**Location:** `cogni-research/references/research-types/`

**Content:**

- Pure definitions — what dimensions/structures exist
- Framework structure — how components relate conceptually
- MECE validation — why the structure is complete
- Cross-references — which frameworks reference each other

**Characteristics:**

- Flat file structure (no subdirectories except `archived/`)
- Lean files (definitions only, no operational guidance)
- Composable (research types can reference shared frameworks like TIPS)
- Stable (changes infrequent, propagation required when changed)

### HOW References (Skill-specific phase files)

**Location:** `cogni-research/skills/{skill-name}/references/`

**Content:**

- Operational guidance — how to use the definitions
- PICOT patterns — how to generate questions
- Synthesis workflows — how to process findings
- Validation scripts — how to verify output
- Word counts, citation requirements, formatting rules

**Characteristics:**

- Skill-optimized (tailored for each skill's workflow)
- Design-time compiled (derived from WHAT definitions)
- Phase-specific (different HOW for Phase 2 vs Phase 4)
- Mutable (can evolve independently from master WHAT)

---

## Decision Framework: Runtime vs Design-Time Loading

### Use Runtime Loading When:

- Content is dynamic (changes per research project)
- Content is large and not always needed
- Multiple skills share identical operational patterns
- Backward compatibility requires gradual migration

### Use Design-Time Compilation When:

- Content is skill-specific (different skills need different guidance)
- Content is frequently accessed (loaded every execution)
- Token efficiency is critical (compile once, use many times)
- Skills need different HOW interpretations of same WHAT

---

## Token Budget Guidelines

| Content Type | Size Target | Loading Pattern |
|--------------|-------------|-----------------|
| WHAT definition | 2-5 KB | Runtime (small, shared) |
| HOW phase file | 5-15 KB | Design-time (skill-specific) |
| Combined guidance | 15-25 KB | Split across phases |

**Threshold Rule:** If content exceeds 10 KB and is skill-specific, consider design-time compilation into phase files.

---

## File Naming Conventions

### Master WHAT Files

```
research-types/
├── {framework-name}.md           # Primary definition
├── tips-framework.md             # Shared synthesis structure
└── archived/{old-structure}/     # Deprecated files
```

### Skill HOW Files

```
skills/{skill-name}/references/
├── phase-workflows/
│   ├── phase-2-analysis-{research-type}.md         # Research-type-specific
│   ├── phase-3-planning-{research-type}.md         # Research-type-specific
│   ├── phase-4a-synthesis-hub-cross.md               # Generic synthesis
│   └── (arc-specific synthesis delegated to cogni-narrative:narrative-writer)
```

---

## Composition Pattern

Research types can compose shared frameworks:

```
smarter-service.md
├── Uses: tips-framework.md (for trend entity structure)
├── Defines: 4 dimensions (Externe Effekte, Neue Horizonte, ...)
└── Defines: Action horizons (Act, Plan, Observe)

lean-canvas.md
├── Defines: 9 blocks (Problem, Customer Segments, ...)
└── Uses: Generic synthesis (no TIPS dependency)
```

**Composition Rule:** Reference shared frameworks by name, don't duplicate content.

---

## Anti-Patterns

### Mixed WHAT/HOW Content

**Wrong:**

```markdown
## Dimension Definition
Externe Effekte focuses on external forces...

## How to Generate Questions
Use PICOT pattern: P={population}, I={intervention}...
```

**Right:**

```markdown
# smarter-service.md (WHAT)
## Dimension Definition
Externe Effekte focuses on external forces...

# phase-2-analysis-smarter-service.md (HOW)
## How to Generate Questions
Use PICOT pattern: P={population}, I={intervention}...
```

### Subdirectory Proliferation

**Wrong:**

```
research-types/
├── smarter-service/
│   ├── dimensions.md
│   ├── synthesis-template.md
│   └── integration-guide.md
```

**Right:**

```
research-types/
├── smarter-service.md              # All WHAT in one file
└── archived/smarter-service/       # Old structure preserved
```

---

## Version History

- **v1.0 (Sprint 438):** Initial design principles document
