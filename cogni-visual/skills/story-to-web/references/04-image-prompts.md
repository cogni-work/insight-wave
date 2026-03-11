# Image Prompt Engineering for Web Narratives

## Purpose

Define image formats, prompt patterns, and generation guidelines for web narrative sections.

---

## Image Formats by Section Type

| Section Type | Image Role | Dimensions | Aspect Ratio | Type |
|-------------|-----------|------------|-------------|------|
| hero | Background | 1440 x 600px | 2.4:1 (wide) | stock or ai |
| feature-alternating | Feature photo | 560 x 400px | 16:10 | stock or ai |
| problem-statement | Optional accent | 400 x 300px | 4:3 | stock |
| feature-grid | Card icons | — | — | icon_font (no image) |
| stat-row | — | — | — | No images |
| testimonial | — | — | — | No images (text-only) |
| comparison | — | — | — | No images (text-only) |
| timeline | — | — | — | No images (text-only) |
| cta | — | — | — | No images |
| text-block | — | — | — | No images |

---

## Image Prompt Reasoning Process

Before writing any image prompt, work through these four steps in order. This chain-of-thought ensures each prompt is purposeful, style-consistent, and technically correct.

### Step 1: Understand the Section Message

Read the section headline, body text, and arc role. Identify:

- **Core subject:** What is this section fundamentally about? (e.g., sensor technology, cost pressure, data analytics)
- **Emotional register:** Is this section about a problem (tension, urgency), a solution (capability, precision), or proof (confidence, results)?
- **Visual anchor:** What single physical or conceptual object best represents the message? Pick ONE dominant subject, not a collage.

### Step 2: Match the Visual to the Message

Map the section's arc role to a visual approach:

| Arc Role | Visual Approach | Example Subjects |
|----------|----------------|-----------------|
| hook (hero) | Aspirational wide shot of the industry environment | Factory floor, city skyline, lab panorama |
| problem | Close-up showing the consequence or pain point | Idle machine, warning indicator, empty production line |
| solution | Detail shot of the technology or capability | Sensor on a spindle, dashboard interface, data flow |
| proof | Abstract visualization of results or transformation | Upward graph, connected network, before/after states |
| roadmap | Process or pathway visualization | Converging paths, stepping stones, timeline flow |

### Step 3: Align with the Style Guide

Check the brief's `style_guide` field. Every image prompt must end with a `Style:` suffix that reflects the selected guide's aesthetic. Common mappings:

| Style Guide Aesthetic | Style Suffix |
|----------------------|-------------|
| Corporate / professional | `Style: professional stock photography, corporate technology.` |
| Bold / dark / high-contrast | `Style: dramatic lighting, high contrast, cinematic.` |
| Warm / consulting / approachable | `Style: warm natural lighting, approachable, editorial.` |
| Minimal / clean / data-driven | `Style: clean minimal composition, muted tones, modern.` |
| Industrial / engineering | `Style: industrial photography, precision engineering, technical.` |

If the style guide does not map cleanly, default to `Style: professional stock photography, modern, clean.`

### Step 4: Compose the Prompt

Assemble the prompt using the appropriate formula (hero or feature). Verify:

- [ ] Single dominant subject (not a list of unrelated objects)
- [ ] "No text, no people" included
- [ ] Aspect ratio or format specified
- [ ] Style suffix matches the brief's style guide
- [ ] Color temperature matches other prompts in this brief (all warm OR all cool)

---

## Hero Background Pattern

The hero section uses a full-width background image with a dark overlay:

```
1. Create image frame (1440 x 600px, fill_container width)
2. Generate image via G(frame_id, "stock" or "ai", "{prompt}")
3. Add overlay frame on top: fill #000000B3 (black at 70% opacity)
4. Add content on top of overlay
```

### Hero Image Prompt Formula

```
Professional {photograph/illustration} of {subject relevant to narrative},
{key visual elements}, {lighting/mood}. Wide panoramic shot.
No text, no people. 16:9 aspect ratio.
Style: {style_guide aesthetic}.
```

**Example:**
```
Professional photograph of a modern smart factory production floor,
CNC machines with glowing sensor nodes, blue ambient lighting,
data visualization overlays on glass surfaces. Clean, high-tech,
wide panoramic shot. No text, no people. 16:9 aspect ratio.
Style: professional stock photography, corporate technology.
```

**Key rules:**
- Always specify "No text, no people" to avoid rendering issues
- Match the industry context from the narrative
- Reference the style guide aesthetic for consistency
- Wide format (panoramic, 16:9 minimum)

---

## Feature Image Pattern

Feature-alternating sections use side-by-side images:

```
1. Create image frame (560 x 400px, cornerRadius: 12)
2. Generate image via G(frame_id, "stock" or "ai", "{prompt}")
3. Image sits beside text content in horizontal layout
```

### Feature Image Prompt Formula

```
{Close-up/Detail/Abstract} {photograph/illustration} of {specific subject},
{key visual detail}, {mood/lighting}.
{Format}. No text, no people.
Style: {style_guide aesthetic}.
```

**Rules:**
- Use square or 16:10 format (560x400 display)
- Focus on the specific feature being described
- Match the section's message (sensor = close-up of sensor)
- Consistent aesthetic across all feature images in the same brief

---

## Stock vs AI Decision Tree

Follow this branching logic to choose between `"stock"` and `"ai"` for each image. The default is `"ai"` unless the stock path explicitly applies.

```
START
  |
  v
Is the subject a simple, concrete, real-world object
that can be described in 2-3 common keywords?
(e.g., "office workspace", "factory floor", "laptop desk")
  |
  +-- YES --> Can you describe it in exactly 2-3 words
  |           without adjectives, modifiers, or style direction?
  |             |
  |             +-- YES --> Use "stock"
  |             |           Prompt = just the 2-3 keywords
  |             |           Example: "factory floor", "server room"
  |             |
  |             +-- NO  --> Use "ai"
  |                         (Unsplash fails with >4 keywords)
  |
  +-- NO  --> Use "ai"
              (Abstract concepts, data visualization, futuristic
               scenarios, specific compositions, styled scenes)
```

### Why This Matters

Unsplash (the stock provider behind `"stock"`) is a keyword search engine, not a prompt interpreter. It returns relevant results for simple noun phrases like "modern office" but returns nothing or irrelevant images for descriptive prompts like "close-up photograph of precision vibration sensors mounted on a CNC machine spindle with blue accent lighting." Complex prompts MUST use `"ai"`.

### Decision Examples

| Image Need | Keywords | Type | Reasoning |
|-----------|----------|------|-----------|
| Hero bg: smart factory | Cannot reduce below 4 words | `"ai"` | Need specific composition, lighting, and mood |
| Feature: vibration sensors on machinery | "vibration sensor CNC" is too specific for stock | `"ai"` | Specific industrial subject with styling |
| Feature: abstract data flow visualization | Abstract concept, no real-world equivalent | `"ai"` | Conceptual, not photographable |
| Problem: empty production line (simple accent) | "empty factory" | `"stock"` | Simple 2-word concrete subject |
| Hero bg: generic office for SaaS narrative | "modern office" | `"stock"` | Simple 2-word concrete subject |
| Feature: neural network processing data | Abstract concept | `"ai"` | Not a photographable real-world object |

---

## Prompt Consistency Rules

All image prompts in a single brief must:

1. **Share a style suffix** — End with the same `Style:` description
2. **Match color temperature** — All warm OR all cool (not mixed)
3. **Match industry context** — Factory images for manufacturing, lab images for healthcare
4. **Avoid text and people** — Always include "No text, no people"
5. **Specify format** — Include dimensions or aspect ratio guidance

---

## Few-Shot Worked Examples

These three examples demonstrate the complete reasoning chain from section content to final image prompt. Each covers a different industry, section type, and visual challenge.

### Example A: Manufacturing / Hero / Why-Change Arc

**Section content:**
```yaml
type: hero
arc_role: hook
headline: "Predictive Maintenance macht Ihre Fertigung unaufhaltsam"
subline: "Senken Sie ungeplante Stillstande um 73%..."
style_guide: "Corporate Tech"
```

**Step 1 — Section message:** The hero introduces a manufacturing predictive maintenance narrative. The core subject is a modern production environment with smart technology. The emotional register is aspirational (promise of transformation).

**Step 2 — Visual approach:** Hero/hook calls for an aspirational wide shot of the industry environment. The visual anchor is a smart factory floor — the physical space where the transformation happens.

**Step 3 — Style alignment:** "Corporate Tech" maps to professional stock photography with corporate technology aesthetic. Color temperature: cool (blue ambient lighting fits both the tech theme and the guide).

**Step 4 — Compose and verify:**

```
Professional photograph of a modern smart factory production floor,
CNC machines with glowing sensor nodes, blue ambient lighting,
data visualization overlays on glass surfaces. Clean, high-tech,
wide panoramic shot. No text, no people. 16:9 aspect ratio.
Style: professional stock photography, corporate technology.
```

Verification: Single subject (factory floor). "No text, no people" present. Wide format specified. Style suffix matches guide. Cool color temperature (blue) — consistent with other prompts in this brief.

**Stock vs AI decision:** Cannot describe in 2-3 keywords (need specific composition with sensor nodes, lighting, overlays). Use `"ai"`.

---

### Example B: Healthcare / Feature-Alternating / Problem-Solution Arc

**Section content:**
```yaml
type: feature-alternating
arc_role: solution
headline: "Remote Patient Monitoring reduziert Klinikbesuche um 40%"
body: "Wearable-Sensoren ubermitteln Vitalwerte in Echtzeit an das Arzteteam..."
style_guide: "Clean Medical"
```

**Step 1 — Section message:** This feature section describes remote patient monitoring technology. Core subject: medical wearable sensors transmitting data. Emotional register: capability and precision (solution role).

**Step 2 — Visual approach:** Solution sections need a detail shot of the technology. Visual anchor: a medical wearable device — the specific technology being described.

**Step 3 — Style alignment:** "Clean Medical" maps to clean minimal composition with clinical tones. Color temperature: cool/neutral (white, light blue, clinical).

**Step 4 — Compose and verify:**

```
Detail photograph of a modern medical wearable sensor device,
sleek white hardware with subtle LED indicator, clinical setting
with soft diffused lighting. Clean, precise composition.
Square format. No text, no people.
Style: clean minimal composition, clinical, modern healthcare.
```

Verification: Single subject (wearable device). "No text, no people" present. Square format specified. Style suffix matches guide. Cool/neutral temperature — consistent with other healthcare prompts.

**Stock vs AI decision:** Specific medical device with particular composition and lighting needs. Cannot reduce to 2-3 stock keywords. Use `"ai"`.

---

### Example C: Financial Services / Feature-Alternating / Argument Arc

**Section content:**
```yaml
type: feature-alternating
arc_role: evidence
headline: "Automatisierte Compliance spart 12.000 Arbeitsstunden pro Jahr"
body: "KI-gestutzte Regelprufung scannt Transaktionen in Echtzeit..."
style_guide: "Corporate Finance"
```

**Step 1 — Section message:** This feature section presents automated compliance as evidence. Core subject: automated transaction scanning. Emotional register: efficiency and reliability (evidence role).

**Step 2 — Visual approach:** Evidence sections call for abstract visualization of results. Visual anchor: flowing data streams being organized and filtered — representing the automated scanning process.

**Step 3 — Style alignment:** "Corporate Finance" maps to professional, conservative, data-driven aesthetic. Color temperature: cool (dark blues, greens — financial sector palette).

**Step 4 — Compose and verify:**

```
Abstract visualization of automated data processing,
flowing streams of financial data being filtered through
a geometric compliance framework, dark blue and emerald green
color palette. Clean, structured composition.
Square format. No text, no people.
Style: professional corporate finance, data-driven, conservative.
```

Verification: Single subject (data filtering process). "No text, no people" present. Square format specified. Style suffix matches guide. Cool temperature (blues, greens) — consistent.

**Stock vs AI decision:** Abstract concept (data flowing through a compliance framework). No real-world photographic equivalent. Use `"ai"`.

---

## Anti-Patterns

These are common image prompt mistakes. Each anti-pattern shows the problem, why it fails, and the corrected version.

### Anti-Pattern 1: Too Vague

```
BAD:  "Technology image, modern, professional."
WHY:  No subject. AI generators produce generic abstract blobs.
      No format, no style suffix, no constraints.

GOOD: "Abstract visualization of interconnected IoT sensor network,
       data nodes linked by glowing pathways, dark background with
       blue accent highlights. Clean composition.
       Square format. No text, no people.
       Style: professional stock photography, corporate technology."
```

### Anti-Pattern 2: Too Many Keywords for Stock

```
BAD:  G(frame, "stock", "modern smart factory production floor with
      CNC machines and glowing sensor nodes and blue ambient lighting
      and data visualization overlays")
WHY:  Unsplash is a keyword search engine. Prompts longer than 3-4
      words return no results or irrelevant images.

GOOD: G(frame, "ai", "Professional photograph of a modern smart factory
      production floor, CNC machines with glowing sensor nodes, blue
      ambient lighting. Wide panoramic shot. No text, no people.
      Style: professional stock photography, corporate technology.")

  OR (if stock is truly appropriate):

GOOD: G(frame, "stock", "smart factory")
```

### Anti-Pattern 3: Requesting Text in Images

```
BAD:  "Dashboard showing '73% Reduction' with chart labels and
       axis text displaying quarterly revenue data."
WHY:  AI image generators render text poorly — blurred, misspelled,
      or garbled characters. Text overlays are added as Pencil MCP
      text nodes, not baked into images.

GOOD: "Abstract data dashboard visualization with upward-trending
       chart lines and geometric data blocks, dark background with
       green accent highlights. Clean composition.
       Square format. No text, no people.
       Style: professional stock photography, corporate technology."
```

### Anti-Pattern 4: Requesting People

```
BAD:  "Team of engineers collaborating around a manufacturing dashboard,
       pointing at screens and discussing sensor data."
WHY:  AI-generated people have uncanny valley artifacts — distorted
      hands, asymmetric faces, merged limbs. Pencil MCP renders these
      as large background images where such artifacts are visible.

GOOD: "Modern engineering workstation with multiple monitors displaying
       industrial sensor dashboards, warm task lighting, organized
       technical workspace. No text, no people.
       Style: professional stock photography, corporate technology."
```

### Anti-Pattern 5: Inconsistent Style Across a Brief

```
BAD (brief with 3 feature images):
  Image 1: "...warm sunset lighting...Style: editorial photography."
  Image 2: "...cold blue neon glow...Style: cyberpunk futuristic."
  Image 3: "...watercolor illustration...Style: hand-drawn artistic."
WHY:  Mixed styles destroy visual coherence. The web narrative looks
      like a collage of unrelated stock photos.

GOOD (same brief, consistent):
  Image 1: "...blue ambient lighting...Style: professional stock photography, corporate technology."
  Image 2: "...cool blue accent highlights...Style: professional stock photography, corporate technology."
  Image 3: "...subtle blue data overlays...Style: professional stock photography, corporate technology."
```

### Anti-Pattern 6: Kitchen Sink Prompt

```
BAD:  "A beautiful stunning incredible amazing photorealistic 8K HDR
       ultra-detailed masterpiece of a factory with robots and sensors
       and conveyor belts and quality control and packaging and shipping
       and management dashboards and KPIs."
WHY:  Too many subjects compete for attention. AI generators average
      them all into an incoherent mush. Modifier stacking ("stunning
      incredible amazing") adds no useful information.

GOOD: "Close-up photograph of an industrial robotic arm performing
       precision assembly, subtle sensor indicator lights visible,
       clean factory environment with soft diffused lighting.
       Square format. No text, no people.
       Style: professional stock photography, corporate technology."
```

---

## Consistency Self-Check

After generating all image prompts for a brief, run this verification pass. For each check, compare every image prompt against every other image prompt in the same brief.

### Checklist

```
FOR each image_prompt in the brief:
  1. STYLE SUFFIX — Does this prompt end with the same Style: line
     as all other prompts in this brief?
     IF NO: Standardize to the brief's style guide aesthetic.

  2. COLOR TEMPERATURE — Does this prompt use the same temperature
     family (warm OR cool) as all other prompts?
     Warm indicators: "warm lighting", "golden", "amber", "sunset"
     Cool indicators: "blue", "cool", "clinical", "silver", "neon"
     IF MIXED: Align all prompts to the dominant temperature
     (whichever appears in the hero prompt).

  3. INDUSTRY CONTEXT — Does this prompt reference the same industry
     environment as the narrative?
     IF manufacturing narrative: all images should show factory/machine contexts
     IF healthcare narrative: all images should show clinical/medical contexts
     IF MISMATCHED: An image of a server room in a manufacturing
     narrative breaks immersion. Realign to the correct industry.

  4. SUBJECT ISOLATION — Does this prompt describe ONE dominant
     subject, or does it list multiple unrelated objects?
     IF MULTIPLE: Pick the single most relevant subject and remove the rest.

  5. CONSTRAINTS PRESENT — Does this prompt include:
     - "No text, no people"
     - Format specification (aspect ratio or dimensions)
     IF MISSING: Add them.

  6. TYPE CORRECTNESS — Is the G() type ("stock" or "ai") correct
     per the decision tree?
     IF stock prompt has >3 keywords: Switch to "ai".
     IF ai prompt is just 2 keywords: Consider switching to "stock".
```

### Example Self-Check Output

```
Brief: Predictive Maintenance im Maschinenbau (3 images)

  Hero bg:     Style OK | Cool (blue) | Manufacturing OK | Single subject OK | Constraints OK | ai OK
  Feature 1:   Style OK | Cool (blue) | Manufacturing OK | Single subject OK | Constraints OK | ai OK
  Feature 2:   Style OK | Cool (grey-to-blue) | Manufacturing OK | Single subject OK | Constraints OK | ai OK

  Result: PASS — all 6 checks consistent across 3 images.
```

---

## Edge Cases

### Unusual Industries

Some industries lack obvious visual subjects. Use these fallback strategies:

| Industry | Challenge | Visual Strategy |
|----------|-----------|----------------|
| Insurance / legal | Abstract services, no physical product | Use abstract geometric patterns representing protection, networks, or document flows |
| Consulting / advisory | Knowledge work, intangible deliverables | Use architectural/spatial metaphors — bridges, pathways, structured frameworks |
| Education / training | People-centric but no people allowed | Focus on the learning environment — empty lecture halls, interactive displays, book arrangements |
| Agriculture / food | Risk of looking generic or clip-art-like | Use close-up macro shots of specific produce, soil texture, or precision farming equipment |
| Government / public sector | Institutional, risk of looking dull | Use civic architecture, public spaces, or abstract representations of public infrastructure |

### Abstract Topics

When a section discusses a purely abstract concept (strategy, culture, digital transformation), follow this escalation:

```
1. FIRST TRY: Find a concrete metaphor for the concept.
   "Digital transformation" → close-up of old mechanical gears
   transitioning to modern digital circuitry
   "Company culture" → architectural interior showing open,
   collaborative workspace design (no people)

2. IF no concrete metaphor fits: Use a data/network visualization.
   "Strategic alignment" → geometric nodes converging toward
   a central point, abstract network diagram

3. IF the concept is too abstract for any image: OMIT the image.
   Not every section needs an image. A well-designed text section
   with strong typography can be more effective than a forced,
   irrelevant image. Set image_prompt to empty/omit it.
```

### When No Good Image Fits

Sometimes the best decision is no image. Prefer omitting an image over forcing a bad one in these cases:

- **Section is primarily data-driven** (stat-row, comparison) — let the numbers speak
- **Section content is highly specific** and no visual can represent it without being misleading
- **The image would be a generic decoration** that adds no meaning (a random abstract blue wave for every tech topic)
- **The section type does not require images** — check the Image Formats table above; most section types are text-only by design

When omitting an image from a section that normally uses one (e.g., feature-alternating), note it in the brief:

```yaml
image_prompt: ""  # Omitted: section content is too abstract for meaningful imagery
```

### Multi-Language Considerations

Image prompts are always written in English regardless of the brief's `language` field. AI image generators perform best with English prompts. Do NOT translate image prompts to German or other languages — only the visible text content (headlines, body, labels) follows the brief's language setting.

---

## Icon Usage

For `feature-grid` and `stat-row` sections, use Pencil MCP `icon_font` nodes instead of generated images:

```yaml
icon: "activity"     # Lucide icon name
```

Common icons by topic:

| Topic | Icon Name |
|-------|-----------|
| Warning/risk | `triangle-alert` |
| People/workforce | `users` |
| Decline/drift | `trending-down` |
| Cost/money | `euro`, `dollar-sign` |
| Success/proven | `check-circle` |
| Speed/time | `clock`, `zap` |
| Data/analytics | `activity`, `bar-chart` |
| Settings/process | `settings`, `cog` |
| Target/goal | `target`, `flag` |
| Shield/security | `shield` |

> **Note:** Lucide icon names have evolved over time. Some older names (e.g., `alert-triangle`) were reversed to `triangle-alert`. If an icon doesn't render, try the reversed name variant (swap the two hyphenated parts).
