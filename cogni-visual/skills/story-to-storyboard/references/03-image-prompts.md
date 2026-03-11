# Image Prompts for Storyboard Posters

## Purpose

Define patterns for generating print-resolution AI image prompts for storyboard poster sections. Storyboards reuse web image patterns (from `story-to-web/references/04-image-prompts.md`) with print-specific adaptations. Images must work at A1 print scale.

**Key principle:** The skill reads `story-to-web/references/04-image-prompts.md` for base web image patterns. This file defines ONLY the print-specific overrides.

---

## Print-Specific Overrides

### Resolution Suffix

Every image prompt in a storyboard MUST end with:
```
Style: print resolution, high detail. No text, no people.
```

This replaces the web-standard resolution instruction.

### Image Count per Poster

- **Max 2 images per poster** (one per image-capable section within the poster)
- Image-capable sections: `hero`, `feature-alternating`, `feature-grid` (optional header image)
- Non-image sections: `stat-row`, `comparison`, `timeline`, `cta`, `text-block`, `testimonial`

### Image Dimensions

Images fill their section's content width (1440px at base resolution). Height is proportional to the section's height allocation within the poster.

```
Example: 2-section poster (55/45 split), first section is hero with image:
  Section 1 height: 1058px (55% of 1924px content area)
  Image frame: 1440 x 1058 at base resolution
  At A1 print: 3508 x 2579 px

Example: 2-section poster (50/50 split), second section is feature-alternating:
  Section 2 height: 962px (50% of 1924px content area)
  Portrait adaptation: image on top at 40% of section height
  Image frame: 1440 x 385 (40% of 962) at base resolution
```

---

## Image Prompt Patterns by Section Type

### hero (Background Image with Overlay)

```
{industry}-themed illustration of a wide panoramic landscape.
Left section: {current state — muted, grey, worn} suggesting the problem.
Right section: {future state — bright, modern, efficient} suggesting the solution.
Center: transition zone showing change in progress.
Color palette: {primary}, {accent}, {background} from theme.
Style: print resolution, high detail. No text, no people.
```

**Renderer pattern:** Create image frame, G(), add overlay frame `#000000B3`, content on top.

### feature-alternating (Content Image)

```
Illustration of {concrete subject from headline}.
{Detailed scene description with 3-4 specific visual elements}.
{Context matching the industry}.
Mood: {arc_role_mood}.
Color palette: {theme_colors}.
Style: print resolution, high detail. No text, no people.
```

**Renderer pattern:** On portrait poster, image fills top 40% of section height. Full width.

---

## Arc Role to Mood Mapping

| Arc Role | Mood | Visual Treatment |
|----------|------|-----------------|
| `hook` | Dramatic, inviting | Panoramic, light-to-dark transition |
| `problem` | Tense, concerning | Darker tones, sharp contrasts |
| `urgency` | Urgent, pressured | Warm/hot tones, scarcity symbols |
| `solution` | Confident, bright | Primary brand color, clean lines |
| `proof` | Trustworthy, solid | Stable composition, evidence of success |
| `roadmap` | Forward-looking | Perspective lines, horizon, path |
| `call-to-action` | Inviting, aspirational | Bright accent color, open composition |

---

## Art Style Consistency

All image prompts within a storyboard share the same visual style. The style is driven by the selected **style guide** (not a manual `art_style` parameter). The style guide's aesthetic direction determines illustration approach.

When generating prompts, maintain consistency by:
1. Using the same level of detail across all images
2. Using the same color temperature and mood language
3. Using the same composition approach (flat vs. dimensional, abstract vs. concrete)

---

## Prompt Quality Checklist

For every image prompt, verify:

- [ ] "Print resolution, high detail" included?
- [ ] "No text, no people" included?
- [ ] Theme colors referenced?
- [ ] Subject is concrete (not abstract)?
- [ ] Mood matches arc role?
- [ ] Industry context applied?
- [ ] Consistent style across all poster images?
