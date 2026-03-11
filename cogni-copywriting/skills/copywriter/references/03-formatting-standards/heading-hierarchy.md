---
title: Heading Hierarchy Standards
type: formatting-standard
category: formatting
tags: [headers, hierarchy, structure, scannability]
audience: [all]
related:
  - visual-elements
  - markdown-basics
version: 2.0
last_updated: 2026-02-25
---

# Heading Hierarchy Standards

This reference defines the rules for structuring headings in business documents. Correct heading hierarchy makes documents scannable, navigable, and professional. Apply these rules every time you create or revise a document.

## Core Rules

<rules>
1. Use exactly one H1 per document. The H1 is the document title.
2. Limit depth to three levels below H1: H2, H3, H4. Never use H5 or H6.
3. Never skip levels. An H3 must appear inside an H2. An H4 must appear inside an H3.
4. Maintain parallel grammatical structure across all headings at the same level within a section.
5. Front-load keywords: place the most important word(s) at the start of every heading.
6. Keep headings concise: H1 3-8 words, H2 2-6 words, H3 2-5 words, H4 2-4 words.
7. Make every heading specific and descriptive. Generic headings like "Overview" or "Details" are prohibited.
8. If you need more than three levels, restructure the content rather than adding depth.
</rules>

## How Each Level Works

Think of heading levels as a decision tree. Each level answers a different question for the reader.

### H1: Document Title (exactly one)

The H1 names the entire document. It tells the reader what this document is about in a single line.

```markdown
# Q3 Infrastructure Migration Plan
```

- Appears once, at the top of the document
- 3-8 words, keyword-first
- Matches the document's purpose exactly: if the H1 says "Migration Plan," the document must be a plan, not a report

### H2: Major Sections (primary divisions)

H2 headings divide the document into its main parts. A reader who sees only the H2s should understand the full scope and flow of the document.

```markdown
## Migration Requirements
## Risk Assessment
## Implementation Timeline
## Resource Allocation
```

- 2-6 words each
- Typically 3-7 H2s per document (varies by deliverable type)
- Each H2 represents a distinct topic that could stand on its own

### H3: Subsections (breakdowns within a section)

H3 headings subdivide an H2 into components. They always appear inside an H2 section.

```markdown
## Risk Assessment
### Technical Risks
### Operational Risks
### Financial Risks
```

- 2-5 words each
- Typically 2-5 H3s per H2 section
- Use only when an H2 section covers multiple distinct subtopics

### H4: Detail Level (use sparingly)

H4 headings provide granular breakdowns within an H3. Before using H4, consider whether **bold text** or a list would work better.

```markdown
### Technical Risks
#### Database Compatibility
#### API Version Conflicts
```

- 2-4 words each
- Use only when the H3 genuinely contains multiple distinct sub-subtopics
- If you find yourself reaching for H5, stop and restructure the document

## Parallel Structure

All headings at the same level within a parent section must use the same grammatical form. This is non-negotiable. Mixed forms signal sloppy thinking and break scannability.

### Step-by-step: choosing and applying a form

1. Decide the grammatical form for each heading level before writing any body text.
2. Pick one form per level within each parent section. The three acceptable forms are: gerund phrases ("Defining Requirements"), noun phrases ("Architecture Overview"), or question phrases ("What Is the Problem?").
3. Apply that form consistently to every heading at that level.

### Before/after examples

**Before (broken parallel structure):**
```markdown
## Requirements Definition        <- noun phrase
## Building Prototypes            <- gerund phrase
## Test the Solution              <- imperative verb
## System Deployment Process      <- noun phrase (different pattern)
```

The problem: four headings, three different grammatical forms. A reader scanning these headings must mentally re-parse each one.

**After (consistent gerund form):**
```markdown
## Defining Requirements
## Building Prototypes
## Testing Solutions
## Deploying Systems
```

**After (consistent noun form):**
```markdown
## Requirements Analysis
## Prototype Development
## Solution Testing
## System Deployment
```

Both corrected versions are valid. What matters is consistency within the set.

**Before (broken parallel structure in questions):**
```markdown
## What Is the Problem?
## The Impact on Revenue
## How Do We Solve It?
```

**After (consistent question form):**
```markdown
## What Is the Problem?
## Why Does It Matter?
## How Do We Solve It?
## When Should We Act?
```

## Keyword Front-Loading

Place the most important word at the start of each heading. Readers scan the left edge of text. If the meaningful keyword is buried, the heading fails its navigation purpose.

**Before (keywords buried):**
```markdown
## Strategies for Reducing Costs
## Results from Performance Optimization
## A Guide to Implementing Security
## Detailed Timeline Including All Milestones
```

**After (keywords front-loaded):**
```markdown
## Cost Reduction Strategies
## Performance Optimization Results
## Security Implementation Guide
## Timeline and Milestones
```

**Self-test:** Read only the first two words of each heading. Can you still understand what each section covers? If not, restructure.

## Heading Patterns by Document Type

Different deliverable types call for different heading structures. Use these as starting templates, then adapt to the specific content.

### Memos (short, action-oriented)
```markdown
# [Memo Subject]
## Recommendation                 <- BLUF: state the answer first
## Background                     <- context the reader needs
## Supporting Analysis            <- evidence for the recommendation
## Next Steps                     <- specific actions with owners
```
Typically 3-4 H2 sections. H3 is rarely needed; memos should fit one page.

### Briefs (analytical, focused)
```markdown
# [Brief Title]
## Executive Summary
## Situation Analysis
## Findings
### [Finding Category A]
### [Finding Category B]
## Recommendations
## Implementation Considerations
```
Typically 3-5 H2 sections with H3 subsections under analytical sections.

### Reports (comprehensive, structured)
```markdown
# [Report Title]
## Executive Summary
## Background
## Methodology
## Findings
### [Major Finding 1]
### [Major Finding 2]
## Analysis
## Recommendations
## Appendices
```
Typically 5-10 H2 sections. H3 subsections are common. H4 is acceptable in detailed reports.

### Proposals (persuasive, answer-first)
```markdown
# [Proposal Title]
## Proposed Solution
## Problem Statement
## Benefits and ROI
## Implementation Approach
### Phase 1: [Description]
### Phase 2: [Description]
## Investment Required
## Next Steps
```
Typically 5-7 H2 sections. Lead with the solution, not the problem.

## Structural Patterns

### Answer-First (Pyramid)

Place the conclusion at the top. Supporting evidence follows in descending order of importance.

```markdown
# Research Findings Report
## Key Finding                      <- answer goes here
## Supporting Evidence: Architecture
## Supporting Evidence: Process
## Supporting Evidence: Outcomes
## Methodology
## Appendices
```

### SCQA (Situation-Complication-Question-Answer)

Use for persuasive or recommendation documents that need to build a logical case.

```markdown
# Strategic Recommendation
## Situation                        <- current state
## Complication                     <- what changed or went wrong
## Question                         <- the decision to be made
## Answer                           <- the recommended path
### Supporting Analysis
### Implementation Plan
### Expected Outcomes
```

### Chronological/Process

Use when the content follows a time sequence or workflow.

```markdown
# Project Status Report
## Executive Summary
## Completed Work
## Current Status
## Upcoming Milestones
## Risks and Mitigations
## Appendices
```

## Common Mistakes and Corrections

### Mistake: Exceeding three levels of depth

```markdown
## Section                          <- H2
### Subsection                      <- H3
#### Detail                         <- H4
##### Sub-detail                    <- H5 - NEVER DO THIS
```

**Fix:** Restructure the content. Promote the H4 to H3 by splitting the parent H2 into two H2 sections, or collapse the H5 content into a bold-labeled paragraph or list under the H4.

### Mistake: Generic headings

```markdown
## Overview
## Details
## More Information
## Conclusion
```

These headings tell the reader nothing. Every heading must name the specific content it contains.

**Fix:**
```markdown
## Market Opportunity Summary
## Competitive Landscape Analysis
## Customer Acquisition Strategy
## Recommended Next Steps
```

### Mistake: Headings that are too long

```markdown
## An Analysis of the Various Factors Contributing to Performance Degradation
```

**Fix:** Compress to the essential concept.
```markdown
## Performance Degradation Factors
```

### Mistake: Skipping heading levels

```markdown
## Major Section
#### Detail Level                   <- skipped H3
```

**Fix:** Either insert the missing H3, or promote the H4 to H3 if no intermediate grouping is needed.

```markdown
## Major Section
### Subsection
#### Detail Level
```

## Validation Checklist

Before finalizing any document, verify every item. If any check fails, revise the headings before proceeding.

- H1 appears exactly once and serves as the document title
- No heading level exceeds H4
- No heading levels are skipped (H2 -> H4 without H3)
- All headings at the same level within a section use parallel grammatical structure
- Keywords appear at the start of each heading, not buried mid-phrase
- Every heading is specific and descriptive (no "Overview," "Details," "Misc.")
- H2 headings alone convey the document's full scope and logical flow
- Heading lengths stay within bounds: H1 3-8 words, H2 2-6, H3 2-5, H4 2-4
- Heading density is appropriate for the document type (not too sparse, not too dense)

## See Also
- `visual-elements.md` - visual hierarchy complements heading hierarchy
- `markdown-basics.md` - heading syntax details
- `../01-core-principles/readability-principles.md` - scannability principles
