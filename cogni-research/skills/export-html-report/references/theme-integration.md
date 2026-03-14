# Theme Integration Reference

How to load and apply themes from the cogni-workplace theme system.

## Theme Location

Themes are stored in the cogni-workplace plugin:

```text
$COGNI_WORKPLACE_ROOT/themes/
├── _template/
│   └── theme.md              # Template for new themes
├── digital-x/
│   └── theme.md              # Deutsche Telekom DIGITAL X theme
├── cogni-work/
│   └── theme.md              # Cogni workplace theme
└── {custom-theme}/
    └── theme.md              # User-created themes
```

## Theme File Structure

Each `theme.md` contains:

1. **YAML Frontmatter** - Theme metadata
2. **Design Overview** - Color philosophy, typography approach
3. **CSS Variable Reference** - The extractable CSS block

### Example theme.md Structure

```markdown
---
theme_id: digital-x
theme_name: DIGITAL X
customer: Deutsche Telekom
version: 1.0.0
---

# DIGITAL X Theme

## Overview
...design philosophy...

## Color Palette
...color tables...

## CSS Variable Reference

```css
:root {
    --color-primary: #0d3c55;
    --color-accent: #00d7e9;
    ...
}
```
```

## Extracting CSS Variables

The export script extracts CSS from the `## CSS Variable Reference` section:

```python
def load_theme_css(theme_path: Path) -> str:
    """Extract CSS variables from theme.md."""
    content = theme_path.read_text()

    # Find CSS code block after "## CSS Variable Reference"
    pattern = r'## CSS Variable Reference.*?```css\n(.*?)```'
    match = re.search(pattern, content, re.DOTALL)

    if match:
        return match.group(1).strip()
    return get_fallback_css()
```

## Required CSS Variables

The `report-layout.css` expects these CSS variables to be defined:

### Colors (Required)

| Variable | Description | Example |
|----------|-------------|---------|
| `--color-primary` | Primary brand color | `#0d3c55` |
| `--color-primary-dark` | Darker variant | `#091f2c` |
| `--color-primary-light` | Lighter variant | `#1a5276` |
| `--color-accent` | Accent/highlight color | `#00d7e9` |
| `--color-bg-primary` | Main background | `#ffffff` |
| `--color-bg-secondary` | Secondary background | `#f8fafb` |
| `--color-text-primary` | Primary text | `#0d3c55` |
| `--color-text-secondary` | Secondary text | `#2c5364` |
| `--color-text-muted` | Muted/caption text | `#5a7a8a` |
| `--color-border` | Border color | `#d4dfe5` |

### Typography (Required)

| Variable | Description | Example |
|----------|-------------|---------|
| `--font-primary` | Main body font stack | `'TeleNeoWeb', sans-serif` |
| `--font-heading` | Heading/display font | `'TeleNeo ExtraBold', Georgia, serif` |
| `--font-mono` | Monospace font | `'SF Mono', monospace` |

### Spacing (Required)

| Variable | Description | Example |
|----------|-------------|---------|
| `--spacing-xs` | Extra small | `0.25rem` |
| `--spacing-sm` | Small | `0.5rem` |
| `--spacing-md` | Medium | `1rem` |
| `--spacing-lg` | Large | `1.5rem` |
| `--spacing-xl` | Extra large | `2rem` |

### Badge Colors (Optional)

Tinted backgrounds for the semantic badge system. Each uses a low-opacity version of the semantic color.
If not provided, fallback `rgba()` values in `report-layout.css` are used.

| Variable | Description | Example |
|----------|-------------|---------|
| `--color-badge-dimension` | Dimension/general badge bg | `rgba(13, 60, 85, 0.09)` |
| `--color-badge-horizon-act` | ACT horizon badge bg | `rgba(46, 125, 50, 0.09)` |
| `--color-badge-horizon-plan` | PLAN horizon badge bg | `rgba(237, 108, 2, 0.09)` |
| `--color-badge-horizon-observe` | OBSERVE horizon badge bg | `rgba(90, 122, 138, 0.08)` |
| `--color-badge-evidence-strong` | Strong evidence badge bg | `rgba(46, 125, 50, 0.09)` |
| `--color-badge-evidence-moderate` | Moderate evidence badge bg | `rgba(237, 108, 2, 0.09)` |
| `--color-badge-evidence-weak` | Weak evidence badge bg | `rgba(192, 57, 43, 0.09)` |
| `--color-badge-confidence` | Confidence % badge bg | `rgba(0, 215, 233, 0.09)` |
| `--color-badge-verified` | Verified status badge bg | `rgba(46, 125, 50, 0.09)` |
| `--color-badge-contradicted` | Contradicted status badge bg | `rgba(192, 57, 43, 0.09)` |

### Dimension Colors (Optional)

Dynamic dimension color palette. The export script cycles through these for N dimensions.

| Variable | Description | Example |
|----------|-------------|---------|
| `--color-dim-1` | Dimension 1 color | `#00b8d4` |
| `--color-dim-2` | Dimension 2 color | `#5b2c6f` |
| `--color-dim-3` | Dimension 3 color | `#1e8449` |
| `--color-dim-4` | Dimension 4 color | `#ff6b4a` |
| `--color-dim-5` | Dimension 5 color | `#3b82f6` |
| `--color-dim-6` | Dimension 6 color | `#8b5cf6` |
| `--color-dim-7` | Dimension 7 color | `#ec4899` |
| `--color-dim-8` | Dimension 8 color | `#f59e0b` |

### Shadows (Optional)

| Variable | Description | Example |
|----------|-------------|---------|
| `--shadow-sm` | Small shadow | `0 1px 3px rgba(0,0,0,0.08)` |
| `--shadow-md` | Medium shadow | `0 4px 6px rgba(0,0,0,0.07)` |
| `--shadow-lg` | Large shadow | `0 10px 25px rgba(0,0,0,0.1)` |

### Border Radius (Optional)

| Variable | Description | Example |
|----------|-------------|---------|
| `--radius-sm` | Small radius | `4px` |
| `--radius-md` | Medium radius | `8px` |
| `--radius-lg` | Large radius | `12px` |

## Fallback CSS

If theme loading fails, use these fallback values:

```css
:root {
    /* Primary Colors - Dark Teal */
    --color-primary: #0d3c55;
    --color-primary-dark: #091f2c;
    --color-primary-light: #1a5276;

    /* Accent - Cyan */
    --color-accent: #00d7e9;
    --color-accent-light: #4de8f4;
    --color-accent-dark: #00b8d4;

    /* Backgrounds */
    --color-bg-primary: #ffffff;
    --color-bg-secondary: #f8fafb;
    --color-bg-tertiary: #e8f4f8;

    /* Text */
    --color-text-primary: #0d3c55;
    --color-text-secondary: #2c5364;
    --color-text-muted: #5a7a8a;
    --color-text-light: #ffffff;

    /* Borders */
    --color-border: #d4dfe5;
    --color-border-hover: #b8c9d4;
    --color-border-focus: #00d7e9;

    /* Typography */
    --font-primary: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
    --font-heading: Georgia, 'Times New Roman', serif;
    --font-mono: 'SF Mono', 'Fira Code', Consolas, monospace;

    /* Spacing */
    --spacing-xs: 0.25rem;
    --spacing-sm: 0.5rem;
    --spacing-md: 1rem;
    --spacing-lg: 1.5rem;
    --spacing-xl: 2rem;
    --spacing-2xl: 3rem;

    /* Shadows */
    --shadow-sm: 0 1px 3px rgba(0, 0, 0, 0.08), 0 1px 2px rgba(0, 0, 0, 0.04);
    --shadow-md: 0 4px 6px rgba(0, 0, 0, 0.07), 0 2px 4px rgba(0, 0, 0, 0.04);
    --shadow-lg: 0 10px 25px rgba(0, 0, 0, 0.1), 0 4px 10px rgba(0, 0, 0, 0.06);

    /* Border Radius */
    --radius-sm: 4px;
    --radius-md: 8px;
    --radius-lg: 12px;

    /* Badge Tinted Backgrounds */
    --color-badge-dimension: rgba(13, 60, 85, 0.09);
    --color-badge-horizon-act: rgba(46, 125, 50, 0.09);
    --color-badge-horizon-plan: rgba(237, 108, 2, 0.09);
    --color-badge-horizon-observe: rgba(90, 122, 138, 0.08);
    --color-badge-evidence-strong: rgba(46, 125, 50, 0.09);
    --color-badge-evidence-moderate: rgba(237, 108, 2, 0.09);
    --color-badge-evidence-weak: rgba(192, 57, 43, 0.09);
    --color-badge-confidence: rgba(0, 215, 233, 0.09);
    --color-badge-verified: rgba(46, 125, 50, 0.09);
    --color-badge-contradicted: rgba(192, 57, 43, 0.09);

    /* Dimension Palette */
    --color-dim-1: #00b8d4;
    --color-dim-2: #5b2c6f;
    --color-dim-3: #1e8449;
    --color-dim-4: #ff6b4a;
    --color-dim-5: #3b82f6;
    --color-dim-6: #8b5cf6;
    --color-dim-7: #ec4899;
    --color-dim-8: #f59e0b;
}
```

## Theme Resolution Order

The script searches for themes in this order:

1. `$COGNI_WORKPLACE_ROOT/themes/{theme-id}/theme.md`
2. Relative to script: `../../../cogni-workplace/themes/{theme-id}/theme.md`
3. Common paths:
   - `~/.claude/plugins/marketplaces/cogni-workplace/cogni-workplace/themes/`
   - `~/GitHub/cogni-research/cogni-workplace/themes/`

## Entity Type Colors

For entity type badges, use these semantic mappings:

| Entity Type | CSS Class | Suggested Color |
|-------------|-----------|-----------------|
| dimension | `.entity-dimension` | `--color-accent` |
| finding | `.entity-finding` | `--color-primary-light` |
| claim | `.entity-claim` | `--color-primary` |
| source | `.entity-source` | `--color-text-muted` |

## Verification Status Colors

For claim verification badges:

| Status | CSS Class | Suggested Style |
|--------|-----------|-----------------|
| verified | `.status-verified` | Green accent or checkmark |
| partially-verified | `.status-partial` | Yellow/amber warning |
| unverified | `.status-unverified` | Gray muted |
| contradicted | `.status-contradicted` | Red/error |

## Print Considerations

Theme CSS should include print-friendly overrides:

```css
@media print {
    :root {
        --color-bg-primary: #ffffff;
        --color-text-primary: #000000;
        --shadow-sm: none;
        --shadow-md: none;
        --shadow-lg: none;
    }

    .report-toc {
        display: none;
    }
}
```
