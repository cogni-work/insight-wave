# Style CSS Recipes

CSS rules per style preset, applied via `data-style="{preset}"` on the root `.infographic`
container. All colors reference CSS custom properties from design-variables.json — no
hardcoded hex values.

## CSS Custom Properties (Base)

These are injected into `:root {}` from design-variables.json:

```css
:root {
  --color-primary: {colors.primary};
  --color-secondary: {colors.secondary};
  --color-accent: {colors.accent};
  --color-accent-muted: {colors.accent_muted};
  --color-accent-dark: {colors.accent_dark};
  --color-bg: {colors.background};
  --color-surface: {colors.surface};
  --color-surface2: {colors.surface2};
  --color-surface-dark: {colors.surface_dark};
  --color-border: {colors.border};
  --color-text: {colors.text};
  --color-text-light: {colors.text_light};
  --color-text-muted: {colors.text_muted};
  --color-success: {status.success};
  --color-warning: {status.warning};
  --color-danger: {status.danger};
  --font-headers: {fonts.headers};
  --font-body: {fonts.body};
  --font-mono: {fonts.mono};
  --radius: {radius};
  --shadow-sm: {shadows.sm};
  --shadow-md: {shadows.md};
  --shadow-lg: {shadows.lg};
}
```

## Spacing Variables (per preset)

```css
/* editorial */  --spacing-sm: 16px; --spacing-md: 40px; --spacing-lg: 60px; --padding: 24px;
/* data-viz */   --spacing-sm: 12px; --spacing-md: 24px; --spacing-lg: 32px; --padding: 16px;
/* sketchnote */ --spacing-sm: 16px; --spacing-md: 36px; --spacing-lg: 48px; --padding: 24px;
/* corporate */  --spacing-sm: 12px; --spacing-md: 32px; --spacing-lg: 40px; --padding: 20px;
/* whiteboard */ --spacing-sm: 20px; --spacing-md: 48px; --spacing-lg: 64px; --padding: 24px;
```

---

## editorial

```css
[data-style="editorial"] {
  background: var(--color-bg);
  font-family: var(--font-body);
  color: var(--color-text);
}

[data-style="editorial"] .ig-headline {
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 2.5rem;
  line-height: 1.1;
  letter-spacing: -0.02em;
}

[data-style="editorial"] .ig-block {
  border: 1px solid var(--color-border);
  border-radius: 0;
  padding: var(--padding);
  background: var(--color-bg);
}

[data-style="editorial"] .ig-kpi-number {
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 3.5rem;
  color: var(--color-accent-dark);
}

[data-style="editorial"] .ig-cta-button {
  background: var(--color-primary);
  color: var(--color-text-light);
  border-radius: 0;
  padding: 12px 32px;
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.05em;
}
```

**Key traits:** Sharp edges (radius: 0), thin borders, generous whitespace, accent used
sparingly (only hero numbers and CTA). No shadows, no gradients.

---

## data-viz

```css
[data-style="data-viz"] {
  background: var(--color-bg);
  font-family: var(--font-body);
  color: var(--color-text);
}

[data-style="data-viz"] .ig-kpi-card {
  background: color-mix(in srgb, var(--color-accent) 8%, var(--color-bg));
  border: 1px solid var(--color-border);
  border-radius: var(--radius);
}

[data-style="data-viz"] .ig-kpi-number {
  font-family: var(--font-mono);
  font-weight: 700;
  font-size: 3rem;
  color: var(--color-accent-dark);
}

[data-style="data-viz"] .ig-stat-number {
  font-family: var(--font-mono);
  font-weight: 600;
  font-size: 1.5rem;
}

[data-style="data-viz"] .ig-kpi-label,
[data-style="data-viz"] .ig-stat-label {
  font-size: 0.75rem;
  text-transform: uppercase;
  letter-spacing: 0.05em;
  color: var(--color-text-muted);
}

[data-style="data-viz"] .ig-chart {
  background: var(--color-surface);
  border-radius: var(--radius);
  padding: var(--padding);
}
```

**Key traits:** Monospace numbers, accent tint backgrounds for KPI cards, uppercase muted
labels, chart blocks get visual prominence. Compact spacing.

---

## sketchnote

```css
[data-style="sketchnote"] {
  background: var(--color-surface);
  font-family: var(--font-body);
  color: var(--color-text);
}

[data-style="sketchnote"] .ig-block {
  border: 2px dashed var(--color-primary);
  border-radius: 24px;
  padding: var(--padding);
  background: var(--color-bg);
}

[data-style="sketchnote"] .ig-block:nth-child(odd) {
  transform: rotate(-0.5deg);
}

[data-style="sketchnote"] .ig-block:nth-child(even) {
  transform: rotate(0.5deg);
}

[data-style="sketchnote"] .ig-kpi-number {
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 3.5rem;
  color: var(--color-accent-dark);
}

[data-style="sketchnote"] .ig-step-icon,
[data-style="sketchnote"] .ig-grid-icon {
  width: 64px;
  height: 64px;
}

[data-style="sketchnote"] .ig-cta-button {
  background: var(--color-accent);
  color: var(--color-primary);
  border-radius: 24px;
  padding: 14px 36px;
  font-weight: 600;
}
```

**Key traits:** Dashed borders, large rounded corners (24px), slight rotation on blocks,
larger icons (64px), warm surface background. Playful but professional.

---

## corporate

```css
[data-style="corporate"] {
  background: var(--color-bg);
  font-family: var(--font-body);
  color: var(--color-text);
}

[data-style="corporate"] .ig-title {
  background: var(--color-surface-dark);
  color: var(--color-text-light);
  padding: var(--padding) calc(var(--padding) * 2);
}

[data-style="corporate"] .ig-headline {
  color: var(--color-text-light);
}

[data-style="corporate"] .ig-block {
  border: 2px solid var(--color-border);
  border-radius: 4px;
  padding: var(--padding);
  background: var(--color-bg);
}

[data-style="corporate"] .ig-kpi-number {
  font-family: var(--font-headers);
  font-weight: 700;
  font-size: 3rem;
  color: var(--color-primary);
}

[data-style="corporate"] .ig-kpi-label {
  font-size: 0.8rem;
  text-transform: uppercase;
  letter-spacing: 0.04em;
  color: var(--color-text-muted);
}

[data-style="corporate"] .ig-footer {
  background: var(--color-surface);
  border-top: 2px solid var(--color-primary);
}

[data-style="corporate"] .ig-cta-button {
  background: var(--color-primary);
  color: var(--color-text-light);
  border-radius: 4px;
  padding: 12px 32px;
  font-weight: 600;
}
```

**Key traits:** Dark header, solid borders, minimal border radius (4px), primary color
for numbers (not accent), prominent footer. Conservative and trustworthy.

---

## whiteboard

```css
[data-style="whiteboard"] {
  background: #FFFFFF;
  font-family: var(--font-body);
  color: var(--color-primary);
}

[data-style="whiteboard"] .ig-block {
  border: 2px solid var(--color-primary);
  border-radius: 0;
  padding: var(--padding);
  background: transparent;
}

[data-style="whiteboard"] .ig-headline {
  font-family: var(--font-headers);
  font-weight: 800;
  font-size: 2.5rem;
  color: var(--color-primary);
}

[data-style="whiteboard"] .ig-kpi-number {
  font-family: var(--font-headers);
  font-weight: 800;
  font-size: 4rem;
  color: var(--color-accent);
}

[data-style="whiteboard"] .ig-kpi-label {
  color: var(--color-primary);
  font-weight: 500;
}

[data-style="whiteboard"] .ig-step-connector {
  color: var(--color-accent);
  font-weight: 800;
}

[data-style="whiteboard"] .ig-cta-button {
  background: var(--color-accent);
  color: var(--color-primary);
  border-radius: 0;
  padding: 14px 36px;
  font-weight: 700;
  border: 2px solid var(--color-primary);
}

[data-style="whiteboard"] .ig-footer {
  border-top: 2px solid var(--color-primary);
  color: var(--color-text-muted);
}
```

**Key traits:** White background, black text, accent color only for hero numbers and CTA,
bold borders, no fill on blocks, maximum whitespace. No shadows, no gradients.
