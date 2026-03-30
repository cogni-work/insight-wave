# Workflow: Full Onboarding

**Pipeline**: cogni-workspace → cogni-help courses 1-11
**Duration**: ~8-10 hours total (spread across sessions)
**Use case**: New user learning the complete insight-wave ecosystem

```mermaid
graph LR
    A[Workspace Init] --> B[Course 1: Cowork]
    B --> C[Course 2: Workspace]
    C --> D[Courses 3-7: Core]
    D --> E[Courses 8-10: Advanced]
    E --> F[Course 11: Capstone]
```

## Step 1: Initialize Workspace

**Command**: `/manage-workspace`

**Input**: Your project directory
**Output**: Configured workspace with env vars, settings, themes, and plugin discovery

**Tips**:
- Do this before starting any courses — the workspace provides the foundation
- Choose your language preference (EN/DE) during setup
- Pick a theme with `/pick-theme` — it affects all visual output

## Step 2: Start Learning

**Command**: `/teach 1`

**Output**: Interactive Course 1 (Cowork Fundamentals) — 45 minutes

**Tips**:
- Course 1 is meta — it teaches you how the courses themselves work
- Progress is saved automatically — resume anytime with `/teach 1`
- Check your progress at any time with `/courses`

## Step 3: Follow the Curriculum

Work through courses in order. Each builds on the previous:

| Courses | Focus | Time |
|---------|-------|------|
| 1-2 | Foundation (Cowork + Workspace) | ~1.5 hr |
| 3 | Basic tools (Copy + Narrative + Claims) | ~45 min |
| 4-5 | Strategic intelligence (TIPS) | ~1.5 hr |
| 6 | Portfolio messaging | ~45 min |
| 7 | Visual deliverables | ~45 min |
| 8-10 | Advanced (Research + Marketing + Sales) | ~2.5 hr |
| 11 | Capstone (Consulting orchestration) | ~45 min |

**Tips**:
- Each course has exercises that create real artifacts in `_teacher-exercises/`
- Skip-ahead is allowed if you're already proficient in a topic
- Courses 8-10 have prerequisites — the teach skill checks them automatically
- Course 11 is the capstone — it orchestrates most other plugins

## Step 4: Practice

After completing courses, reinforce learning with real work:

1. Pick a small project in your domain
2. Use `/guide` to find the right plugins for your task
3. Use `/workflow` to see how plugins chain together
4. File issues with `/issues` if you encounter problems

## Common Pitfalls

- **Skipping Course 1**: Even experienced users benefit from understanding how the
  ecosystem is structured. Course 1 is only 45 minutes.
- **Binge learning**: Spread courses across sessions. Exercises build muscle memory
  better when you've had time to let concepts settle.
- **Not doing exercises**: Reading theory without hands-on practice doesn't stick.
  The exercises are designed to be quick and directly applicable.
