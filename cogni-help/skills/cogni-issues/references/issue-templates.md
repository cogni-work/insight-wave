# Issue Templates

Templates for the four issue types. Fill what you can from the conversation — omit
sections entirely if you don't have meaningful content for them. A concise issue with
real information is better than a complete template filled with "N/A".

## Bug Report

**Title format:** `[Bug] {plugin_name}: {short description}`

```markdown
**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}
**Environment:** {os} / Claude Code

### What happened
{description}

### Expected behavior
{expected}

### Steps to reproduce
1. {step1}
2. {step2}
3. {step3}

### Error output / logs
```
{logs}
```

### Additional context
{context}
```

## Feature Request

**Title format:** `[Feature] {plugin_name}: {short description}`

```markdown
**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}

### Use case
{use_case}

### Proposed solution
{proposed_solution}

### Alternatives considered
{alternatives}
```

## Change Request

**Title format:** `[Change] {plugin_name}: {short description}`

```markdown
**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}

### Current behavior
{current_behavior}

### Desired behavior
{desired_behavior}

### Motivation
{motivation}
```

## Question

**Title format:** `[Question] {plugin_name}: {short description}`

```markdown
**Plugin:** {plugin_name} v{version}
**Marketplace:** {marketplace}

### Context
{context}

### Question
{question}

### What I've tried
{tried}
```

## Label Mapping

| Issue type | GitHub label |
|------------|-------------|
| bug | `bug` |
| feature | `enhancement` |
| change-request | `change-request` |
| question | `question` |
