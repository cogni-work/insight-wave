# Layout Renderers

Block YAML → HTML/CSS mapping rules for the `generate-infographic.py` script. Each layout
type defines a page-level CSS Grid composition, and each block type defines its HTML
template within that grid.

## Page Structure

Every infographic page follows this HTML structure:

```html
<div class="infographic" data-style="{style_preset}" data-layout="{layout_type}">
  <header class="ig-title">...</header>
  <main class="ig-content">
    <!-- content blocks in layout-specific grid -->
  </main>
  <div class="ig-cta">...</div>
  <footer class="ig-footer">...</footer>
</div>
```

The `.ig-content` section uses CSS Grid with layout-specific templates.

## Layout Grid Templates

### stat-heavy

```css
.ig-content[data-layout="stat-heavy"] {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  grid-template-rows: auto auto auto;
  gap: var(--spacing-md);
}
/* KPI cards span columns 1-3 in row 1 */
/* Chart spans full width in row 2 */
/* Stat row spans full width in row 3 */
```

### timeline-flow

```css
.ig-content[data-layout="timeline-flow"] {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: auto auto;
  gap: var(--spacing-md);
}
/* Process strip spans full width in row 1 (horizontal steps) */
/* Supporting blocks in row 2 */
```

### comparison

```css
.ig-content[data-layout="comparison"] {
  display: grid;
  grid-template-columns: 1fr 1fr;
  grid-template-rows: auto auto;
  gap: var(--spacing-md);
}
/* Comparison pair spans both columns in row 1 */
/* Supporting blocks in row 2 */
```

### hub-spoke

```css
.ig-content[data-layout="hub-spoke"] {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: auto auto;
  gap: var(--spacing-md);
}
/* SVG diagram centered in row 1 */
/* Supporting blocks in row 2 */
```

### funnel-pyramid

```css
.ig-content[data-layout="funnel-pyramid"] {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: repeat(auto-fill, auto);
  gap: var(--spacing-sm);
}
/* Tier bands stack vertically with decreasing width */
```

### list-grid

```css
.ig-content[data-layout="list-grid"] {
  display: grid;
  grid-template-columns: repeat(var(--grid-cols, 2), 1fr);
  grid-template-rows: auto;
  gap: var(--spacing-md);
}
/* Icon grid items fill the grid */
```

### flow-diagram

```css
.ig-content[data-layout="flow-diagram"] {
  display: grid;
  grid-template-columns: 1fr;
  grid-template-rows: 2fr 1fr;
  gap: var(--spacing-md);
}
/* SVG diagram in row 1 (60% height) */
/* Annotation blocks in row 2 (40% height) */
```

## Block HTML Templates

### title

```html
<header class="ig-title">
  <h1 class="ig-headline">{Headline}</h1>
  <p class="ig-subline">{Subline}</p>
  <p class="ig-metadata">{Metadata}</p>
</header>
```

### kpi-card

```html
<div class="ig-block ig-kpi-card">
  <div class="ig-kpi-icon">{inline SVG if available}</div>
  <div class="ig-kpi-number">{Hero-Number}</div>
  <div class="ig-kpi-label">{Hero-Label}</div>
  <div class="ig-kpi-sublabel">{Sublabel}</div>
  <div class="ig-kpi-source">{Source}</div>
</div>
```

### stat-row

```html
<div class="ig-block ig-stat-row">
  <div class="ig-stat" data-index="0">
    <div class="ig-stat-icon">{inline SVG}</div>
    <div class="ig-stat-number">{number}</div>
    <div class="ig-stat-label">{label}</div>
  </div>
  <!-- repeat for each stat -->
</div>
```

### chart

```html
<div class="ig-block ig-chart">
  <h3 class="ig-chart-title">{Chart-Title}</h3>
  <canvas id="chart-{index}" width="600" height="300"></canvas>
</div>
<script>
  new Chart(document.getElementById('chart-{index}'), {chartConfig});
</script>
```

Chart config uses themed colors from CSS custom properties. The Python script generates
the Chart.js config inline following the patterns from `enrich-report/references/04-chart-patterns.md`.

### process-strip

```html
<div class="ig-block ig-process-strip" data-orientation="{horizontal|vertical}">
  <div class="ig-step" data-index="0">
    <div class="ig-step-icon">{inline SVG}</div>
    <div class="ig-step-label">{label}</div>
  </div>
  <div class="ig-step-connector">→</div>
  <!-- repeat for each step -->
</div>
```

Connector arrows are CSS-styled spans with the accent color.

### text-block

```html
<div class="ig-block ig-text-block">
  <div class="ig-text-icon">{inline SVG}</div>
  <h3 class="ig-text-headline">{Headline}</h3>
  <p class="ig-text-body">{Body}</p>
</div>
```

### comparison-pair

```html
<div class="ig-block ig-comparison">
  <div class="ig-comparison-side ig-comparison-left">
    <div class="ig-comparison-icon">{inline SVG}</div>
    <h3 class="ig-comparison-label">{Left.label}</h3>
    <ul class="ig-comparison-bullets">
      <li>{bullet}</li>
    </ul>
  </div>
  <div class="ig-comparison-divider"></div>
  <div class="ig-comparison-side ig-comparison-right">
    <!-- mirror structure -->
  </div>
</div>
```

### icon-grid

```html
<div class="ig-block ig-icon-grid" style="--grid-cols: {Columns}">
  <div class="ig-grid-item">
    <div class="ig-grid-icon">{inline SVG}</div>
    <div class="ig-grid-label">{label}</div>
    <div class="ig-grid-sublabel">{sublabel}</div>
  </div>
  <!-- repeat for each item -->
</div>
```

### svg-diagram

```html
<div class="ig-block ig-svg-diagram">
  {full inline SVG from concept-diagram-svg agent}
</div>
```

### cta

```html
<div class="ig-cta" data-urgency="{CTA-Urgency}">
  <h2 class="ig-cta-headline">{Headline}</h2>
  <a class="ig-cta-button" href="#">{CTA-Text}</a>
</div>
```

### footer

```html
<footer class="ig-footer">
  <span class="ig-footer-left">{Left}</span>
  <span class="ig-footer-center">{Center}</span>
  <span class="ig-footer-right">{Right}</span>
  <div class="ig-footer-source">{Source-Line}</div>
</footer>
```
