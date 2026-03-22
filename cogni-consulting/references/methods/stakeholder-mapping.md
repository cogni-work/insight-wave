---
name: Stakeholder Mapping
phase: discover
type: divergent
inputs: [engagement-vision, client-context]
outputs: [stakeholder-map, influence-interest-matrix, interview-agenda]
duration_estimate: "30-45 min with consultant"
requires_plugins: []
---

# Stakeholder Mapping

Identify and map the people who influence, are affected by, or have a stake in the engagement outcome.

## When to Use

- Every engagement benefits from stakeholder mapping, but it's critical for:
  - digital-transformation (change management depends on stakeholder alignment)
  - cost-optimization (cost cuts affect people; you need to know who)
  - innovation-portfolio (R&D priorities involve competing stakeholders)

## Guided Prompt Sequence

### Step 1: Identify Stakeholders
Ask the consultant:
- Who are the key decision-makers for this engagement?
- Who will be directly affected by the outcome?
- Who has relevant expertise or data?
- Who could block or accelerate progress?
- Are there external stakeholders (customers, partners, regulators)?

Capture each stakeholder with: name/role, organization, relationship to engagement.

### Step 2: Influence/Interest Matrix
Place each stakeholder on a 2×2 matrix:
- **High influence, high interest** → Manage closely (co-create, regular updates)
- **High influence, low interest** → Keep satisfied (executive summaries, milestone briefings)
- **Low influence, high interest** → Keep informed (progress updates, feedback channels)
- **Low influence, low interest** → Monitor (minimal engagement)

### Step 3: Interview Agenda
For high-influence stakeholders, draft interview questions:
- What does success look like for you personally?
- What are you most concerned about?
- What data or insights do you have that we should factor in?
- What has been tried before? What worked/didn't?

## Output Format

Save as `discover/stakeholder-map.md`:

```markdown
# Stakeholder Map

## Key Stakeholders
| Name/Role | Organization | Influence | Interest | Engagement Strategy |
|---|---|---|---|---|

## Interview Agenda
### [Stakeholder 1]
- Q1: ...
- Q2: ...
```
