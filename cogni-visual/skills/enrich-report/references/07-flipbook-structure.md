# Flipbook Structure

Two-page spread flipbook layout for enriched reports. Replaces the sidebar + scroll layout (06-html-structure.md) when `layout=flipbook`.

The flipbook presents the enriched report as a magazine-like reading experience with 3D page-curl animation. Python emits semantic HTML blocks; JavaScript measures and paginates them at render time to adapt to any screen size.

## Page Structure

```
Page 1 (cover left):   Executive Summary — first H2 section of the report
Page 2 (cover right):  Infographic — full-bleed visual executive summary
Pages 3-N:             Remaining report body, paginated by JS
Back cover (last):     Sources / citations summary (if applicable)
```

On desktop the opening spread shows the exec summary on the left and the infographic on the right. This gives readers narrative context before the data-heavy visual.

## Two-Page Spread Layout (Desktop)

```
                    ┌── book spine
                    v
┌─────────────────┬─────────────────┐
│   LEFT PAGE     │   RIGHT PAGE    │
│                 │                 │
│  Content from   │  Content from   │
│  odd page #     │  even page #    │
│                 │                 │
│                 │                 │
│        3        │        4        │
└─────────────────┴─────────────────┘
    ◄  Pages 3-4 of 28  ►  [≡]
    ━━━━━━━━━━━░░░░░░░░░░░░░░░░░░░
```

- Pages are paired into spreads: [1,2], [3,4], [5,6], ...
- Book spine: 2px vertical divider at center, `var(--border)` color
- Odd pages on left, even pages on right
- Navigation advances by spread (2 pages at a time)

## Single-Page Layout (Mobile / Tablet)

Below 1024px viewport width, the flipbook switches to single-page mode:
- One page fills the viewport width (with 16px padding)
- Navigation advances one page at a time
- Swipe gestures for navigation

## HTML Structure

The agent writes this structure. JavaScript handles pagination after load.

```html
<!DOCTYPE html>
<html lang="{language}">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>{report_title}</title>
  <style>{google_fonts_import} {all_css}</style>
  <script src="https://cdn.jsdelivr.net/npm/chart.js@4"></script>
</head>
<body>
  <!-- Loading indicator (shown during pagination) -->
  <div class="flipbook-loader" id="loader">
    <div class="loader-spinner"></div>
    <div class="loader-text">Preparing flipbook...</div>
  </div>

  <!-- Flipbook container (hidden until pagination complete) -->
  <div class="flipbook" id="flipbook" style="opacity:0">
    <!-- Page 1: Executive Summary (pre-built by agent) -->
    <div class="page page-cover" data-page="1">
      <div class="page-inner">
        <h1 class="cover-title">{report_title}</h1>
        <div class="cover-summary">
          {executive_summary_html}
        </div>
        <div class="cover-meta">{date} &middot; {source_info}</div>
      </div>
      <div class="page-number">1</div>
    </div>

    <!-- Page 2: Infographic (pre-built, full bleed) -->
    <div class="page page-infographic" data-page="2">
      <!-- INFOGRAPHIC_INJECTION_POINT -->
      <div class="page-number">2</div>
    </div>

    <!-- Content stream: JS paginates these blocks into pages 3-N -->
    <div class="content-stream" id="content-stream">
      <!-- Each element is a .block with a data-type attribute -->
      <div class="block" data-type="heading" data-level="2" data-section="section-slug">
        <h2 id="section-slug">Section Title</h2>
      </div>
      <div class="block" data-type="paragraph">
        <p>Paragraph text...</p>
      </div>
      <div class="block" data-type="enrichment" data-enrichment-id="enr-001" data-track="data">
        <div class="chart-container">
          <canvas id="enr-001"></canvas>
        </div>
      </div>
      <div class="block" data-type="paragraph">
        <p>More text...</p>
      </div>
      <div class="block" data-type="enrichment" data-enrichment-id="enr-003" data-track="concept">
        <div class="concept-diagram">
          <svg viewBox="0 0 720 300"><!-- inline SVG --></svg>
        </div>
      </div>
      <!-- ... all remaining content as flat blocks ... -->
    </div>
  </div>

  <!-- Navigation controls -->
  <div class="flipbook-nav" id="nav">
    <button class="nav-btn" id="btn-prev" aria-label="Previous page">&larr;</button>
    <span class="nav-counter" id="page-counter">1-2 of 28</span>
    <button class="nav-btn" id="btn-next" aria-label="Next page">&rarr;</button>
    <button class="nav-btn nav-toc" id="btn-toc" aria-label="Table of contents">&#9776;</button>
  </div>

  <!-- Progress bar -->
  <div class="flipbook-progress">
    <div class="flipbook-progress-bar" id="progress-bar"></div>
  </div>

  <!-- Table of Contents overlay -->
  <div class="toc-overlay" id="toc-overlay">
    <div class="toc-panel">
      <div class="toc-header">
        <span class="toc-title">{toc_label}</span>
        <button class="toc-close" id="btn-toc-close">&times;</button>
      </div>
      <nav class="toc-list" id="toc-list">
        <!-- Populated by JS after pagination: -->
        <!-- <a href="#" data-spread="0" class="toc-h2">Section Title <span>p.3</span></a> -->
        <!-- <a href="#" data-spread="1" class="toc-h3">Subsection <span>p.5</span></a> -->
      </nav>
    </div>
  </div>

  <!-- Keyboard help overlay -->
  <div class="help-overlay" id="help-overlay">
    <div class="help-panel">
      <h3>Keyboard Shortcuts</h3>
      <table>
        <tr><td><kbd>&rarr;</kbd> <kbd>Space</kbd></td><td>Next spread</td></tr>
        <tr><td><kbd>&larr;</kbd></td><td>Previous spread</td></tr>
        <tr><td><kbd>Home</kbd></td><td>First page</td></tr>
        <tr><td><kbd>End</kbd></td><td>Last page</td></tr>
        <tr><td><kbd>T</kbd></td><td>Toggle table of contents</td></tr>
        <tr><td><kbd>F</kbd></td><td>Toggle fullscreen</td></tr>
        <tr><td><kbd>?</kbd></td><td>Toggle this help</td></tr>
        <tr><td><kbd>Esc</kbd></td><td>Close overlay</td></tr>
      </table>
      <button class="help-close" id="btn-help-close">Got it</button>
    </div>
  </div>

  <script>
    {flipbook_javascript}
  </script>
</body>
</html>
```

## Block Types

Every content element in `.content-stream` is wrapped in a `.block` div with a `data-type` attribute. The pagination engine uses these to make intelligent break decisions.

| data-type | Element | Break behavior |
|-----------|---------|---------------|
| `heading` | `<h2>` or `<h3>` | H2 always starts a new page. H3 starts new page only if < 120px remains. |
| `paragraph` | `<p>` | Never split. If it doesn't fit, move to next page. |
| `blockquote` | `<blockquote>` | Never split. Move to next page if needed. |
| `list` | `<ul>` or `<ol>` | Never split. Move to next page if needed. |
| `table` | `<div class="table-wrapper"><table>` | If taller than page, gets own page with `overflow-y: auto`. |
| `enrichment` | Chart, SVG, or summary card | Never split. If doesn't fit, gets own page. Charts max 60% page height. |
| `code` | `<pre><code>` | If taller than page, gets own page with `overflow-y: auto`. |

## CSS Architecture

### Design Tokens

Same `:root {}` custom properties as the scroll layout — colors, fonts, spacing from design-variables.json. The flipbook adds these tokens:

```css
:root {
  /* ... all standard design tokens from 06-html-structure.md ... */

  /* Flipbook-specific */
  --page-width: min(48vw, 520px);     /* single page width (desktop) */
  --page-height: min(92vh, 700px);    /* page height */
  --page-ratio: 1 / 1.35;            /* A4-ish portrait ratio */
  --page-padding: 48px 40px;
  --spine-width: 2px;
  --turn-duration: 0.8s;
  --turn-easing: cubic-bezier(0.645, 0.045, 0.355, 1);
}
```

### Flipbook Container

```css
.flipbook {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  perspective: 2000px;
  perspective-origin: center center;
  background: var(--bg);
  transition: opacity 0.3s ease;
}

.flipbook.ready {
  opacity: 1 !important;
}
```

### Spread Container

```css
.spread {
  display: flex;
  position: relative;
  width: calc(var(--page-width) * 2 + var(--spine-width));
  height: var(--page-height);
}

.spread .page-left,
.spread .page-right {
  width: var(--page-width);
  height: var(--page-height);
  overflow: hidden;
  background: var(--surface);
  box-shadow: var(--shadow-lg);
}

.spread .page-left {
  border-radius: var(--radius) 0 0 var(--radius);
  border-right: var(--spine-width) solid var(--border);
}

.spread .page-right {
  border-radius: 0 var(--radius) var(--radius) 0;
}
```

### Page Inner Content

```css
.page-inner {
  padding: var(--page-padding);
  height: 100%;
  overflow: hidden;
  font-family: var(--font-body);
  font-size: 0.95rem;
  line-height: 1.7;
  color: var(--text);
}

.page-inner h2 {
  font-family: var(--font-headers);
  font-size: 1.5rem;
  font-weight: 600;
  margin: 0 0 16px 0;
  padding-bottom: 8px;
  border-bottom: 2px solid var(--accent);
  color: var(--primary);
}

.page-inner h3 {
  font-family: var(--font-headers);
  font-size: 1.15rem;
  font-weight: 600;
  margin: 16px 0 8px 0;
  color: var(--primary);
}

.page-inner p {
  margin: 0 0 12px 0;
}

.page-inner blockquote {
  margin: 12px 0;
  padding: 8px 16px;
  border-left: 3px solid var(--accent);
  background: var(--surface2);
  border-radius: 0 var(--radius) var(--radius) 0;
  font-style: italic;
}
```

### Page Number

```css
.page-number {
  position: absolute;
  bottom: 16px;
  font-family: var(--font-body);
  font-size: 0.8rem;
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
}

.page-left .page-number { left: 40px; }
.page-right .page-number { right: 40px; }
```

### Cover Page (Page 1)

```css
.page-cover .page-inner {
  display: flex;
  flex-direction: column;
  justify-content: center;
}

.cover-title {
  font-family: var(--font-headers);
  font-size: 2rem;
  font-weight: 700;
  line-height: 1.2;
  margin: 0 0 24px 0;
  color: var(--primary);
  border-bottom: 3px solid var(--accent);
  padding-bottom: 16px;
}

.cover-summary {
  font-size: 1rem;
  line-height: 1.8;
  color: var(--text);
}

.cover-meta {
  margin-top: auto;
  padding-top: 24px;
  font-size: 0.85rem;
  color: var(--text-muted);
  border-top: 1px solid var(--border);
}
```

### Infographic Page (Page 2)

```css
.page-infographic {
  padding: 0;
  overflow: hidden;
}

.page-infographic .infographic-editorial {
  width: 100%;
  height: 100%;
  object-fit: contain;
}

/* Pencil HTML fragment: scale to fit page */
.page-infographic .infographic-pencil-html {
  transform-origin: top left;
  /* JS calculates scale factor based on content size vs page size */
}

/* PNG fallback: center and contain */
.page-infographic .infographic-rendered img {
  width: 100%;
  height: 100%;
  object-fit: contain;
}
```

### Enrichment Containers (within pages)

```css
.page-inner .chart-container {
  max-width: 100%;
  margin: 16px 0;
}

.page-inner .chart-container canvas {
  max-height: 55%;  /* relative to page-inner height, enforced by JS */
}

.page-inner .concept-diagram {
  max-width: 100%;
  margin: 16px 0;
}

.page-inner .concept-diagram svg {
  width: 100%;
  height: auto;
  max-height: 50%;
}

.page-inner .summary-card {
  margin: 12px 0;
  padding: 12px 16px;
  background: var(--surface2);
  border-left: 3px solid var(--accent);
  border-radius: 0 var(--radius) var(--radius) 0;
}
```

### 3D Page-Curl Animation

The page-turn effect uses CSS 3D transforms. Each spread is absolutely positioned; only the current spread is visible. On turn, the right page of the current spread rotates -180deg around its left edge (the spine), revealing the next spread underneath.

```css
/* Spreads are stacked */
.spread {
  position: absolute;
  top: 50%;
  left: 50%;
  transform: translate(-50%, -50%);
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.1s ease;
}

.spread.active {
  opacity: 1;
  pointer-events: auto;
  z-index: 2;
}

.spread.next {
  opacity: 1;
  z-index: 1;  /* underneath current spread */
}

/* The turning page */
.spread.active.turning-forward .page-right {
  transform-origin: left center;
  transform: rotateY(-180deg);
  transition: transform var(--turn-duration) var(--turn-easing);
  z-index: 10;
}

/* Shadow on the page during turn */
.spread.active.turning-forward .page-right::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to left, rgba(0,0,0,0.15) 0%, transparent 40%);
  opacity: 1;
  transition: opacity var(--turn-duration) var(--turn-easing);
}

/* Backward turn: left page of next spread flips back */
.spread.next.turning-backward .page-left {
  transform-origin: right center;
  transform: rotateY(180deg);
  transition: transform var(--turn-duration) var(--turn-easing);
  z-index: 10;
}

.spread.next.turning-backward .page-left::after {
  content: '';
  position: absolute;
  inset: 0;
  background: linear-gradient(to right, rgba(0,0,0,0.15) 0%, transparent 40%);
  opacity: 1;
  transition: opacity var(--turn-duration) var(--turn-easing);
}
```

### Navigation Controls

```css
.flipbook-nav {
  position: fixed;
  bottom: 24px;
  left: 50%;
  transform: translateX(-50%);
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 8px 16px;
  background: rgba(255,255,255,0.85);
  backdrop-filter: blur(12px);
  border-radius: 24px;
  box-shadow: var(--shadow-md);
  z-index: 100;
  font-family: var(--font-body);
}

.nav-btn {
  width: 36px;
  height: 36px;
  border: none;
  border-radius: 50%;
  background: var(--surface);
  color: var(--text);
  cursor: pointer;
  display: flex;
  align-items: center;
  justify-content: center;
  font-size: 1rem;
  transition: background 0.2s, transform 0.15s;
}

.nav-btn:hover {
  background: var(--accent);
  color: var(--primary);
  transform: scale(1.08);
}

.nav-counter {
  font-size: 0.85rem;
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
  min-width: 80px;
  text-align: center;
}
```

### Progress Bar

```css
.flipbook-progress {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 3px;
  background: var(--border);
  z-index: 100;
}

.flipbook-progress-bar {
  height: 100%;
  background: var(--accent);
  transition: width 0.4s cubic-bezier(0.4, 0, 0.2, 1);
  width: 0%;
}
```

### ToC Overlay

```css
.toc-overlay {
  position: fixed;
  inset: 0;
  background: rgba(0,0,0,0.4);
  backdrop-filter: blur(4px);
  opacity: 0;
  pointer-events: none;
  transition: opacity 0.3s ease;
  z-index: 200;
}

.toc-overlay.open {
  opacity: 1;
  pointer-events: auto;
}

.toc-panel {
  position: absolute;
  right: 0;
  top: 0;
  bottom: 0;
  width: min(360px, 80vw);
  background: var(--surface);
  padding: 24px;
  overflow-y: auto;
  transform: translateX(100%);
  transition: transform 0.3s ease;
  box-shadow: var(--shadow-xl);
}

.toc-overlay.open .toc-panel {
  transform: translateX(0);
}

.toc-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
  margin-bottom: 16px;
  padding-bottom: 12px;
  border-bottom: 2px solid var(--accent);
}

.toc-title {
  font-family: var(--font-headers);
  font-size: 1.2rem;
  font-weight: 600;
  color: var(--primary);
}

.toc-close {
  background: none;
  border: none;
  font-size: 1.5rem;
  cursor: pointer;
  color: var(--text-muted);
}

.toc-list a {
  display: flex;
  justify-content: space-between;
  padding: 8px 0;
  text-decoration: none;
  color: var(--text);
  border-bottom: 1px solid var(--border);
  font-size: 0.9rem;
  transition: color 0.15s;
}

.toc-list a:hover {
  color: var(--accent-dark);
}

.toc-list a.toc-h3 {
  padding-left: 16px;
  font-size: 0.85rem;
  color: var(--text-muted);
}

.toc-list a span {
  color: var(--text-muted);
  font-variant-numeric: tabular-nums;
  font-size: 0.8rem;
}

.toc-list a.active {
  color: var(--accent-dark);
  font-weight: 500;
}
```

### Loading Indicator

```css
.flipbook-loader {
  position: fixed;
  inset: 0;
  display: flex;
  flex-direction: column;
  justify-content: center;
  align-items: center;
  gap: 16px;
  background: var(--bg);
  z-index: 300;
  transition: opacity 0.3s ease;
}

.flipbook-loader.hidden {
  opacity: 0;
  pointer-events: none;
}

.loader-spinner {
  width: 40px;
  height: 40px;
  border: 3px solid var(--border);
  border-top-color: var(--accent);
  border-radius: 50%;
  animation: spin 0.8s linear infinite;
}

@keyframes spin {
  to { transform: rotate(360deg); }
}

.loader-text {
  font-family: var(--font-body);
  font-size: 0.9rem;
  color: var(--text-muted);
}
```

### Responsive Breakpoints

```css
/* Tablet: single page, centered */
@media (max-width: 1024px) {
  :root {
    --page-width: min(90vw, 520px);
  }

  .spread {
    width: var(--page-width);
  }

  .spread .page-left,
  .spread .page-right {
    /* In single-page mode, JS builds one-page spreads */
    width: 100%;
    border-radius: var(--radius);
    border-right: none;
  }
}

/* Mobile: full width, touch-optimized */
@media (max-width: 768px) {
  :root {
    --page-width: calc(100vw - 32px);
    --page-padding: 32px 24px;
  }

  .flipbook-nav {
    bottom: 16px;
    padding: 6px 12px;
    gap: 8px;
  }

  .nav-btn {
    width: 32px;
    height: 32px;
  }

  .page-inner h2 {
    font-size: 1.3rem;
  }

  .cover-title {
    font-size: 1.6rem;
  }
}
```

## JavaScript Pagination Engine

The pagination engine runs on `DOMContentLoaded`. It measures each block's rendered height and flows them into fixed-size pages.

### Algorithm

```javascript
document.addEventListener('DOMContentLoaded', function() {
  var stream = document.getElementById('content-stream');
  var flipbook = document.getElementById('flipbook');
  var blocks = Array.from(stream.querySelectorAll('.block'));

  // 1. Determine page dimensions
  var isMobile = window.innerWidth <= 1024;
  var pageHeight = computePageHeight();  // from CSS var or viewport
  var contentHeight = pageHeight - 96;   // subtract padding (48px top + 48px bottom)

  // 2. Pre-built pages (cover + infographic) are pages 1 and 2
  var pages = [];
  var coverPage = document.querySelector('.page-cover');
  var infographicPage = document.querySelector('.page-infographic');
  pages.push(coverPage);
  pages.push(infographicPage);

  // 3. Paginate content blocks into new pages
  var currentPage = createPage(pages.length + 1);
  var usedHeight = 0;

  blocks.forEach(function(block) {
    var type = block.dataset.type;
    var level = block.dataset.level;

    // H2 headings always start a new page (chapter opener)
    if (type === 'heading' && level === '2' && usedHeight > 0) {
      pages.push(currentPage);
      currentPage = createPage(pages.length + 1);
      usedHeight = 0;
    }

    // Measure block height (temporarily append to a measuring container)
    var blockHeight = measureBlock(block, contentHeight);

    // Block exceeds entire page height — give it a full page with scroll
    if (blockHeight > contentHeight) {
      if (usedHeight > 0) {
        pages.push(currentPage);
        currentPage = createPage(pages.length + 1);
      }
      block.style.maxHeight = contentHeight + 'px';
      block.style.overflowY = 'auto';
      currentPage.querySelector('.page-inner').appendChild(block);
      pages.push(currentPage);
      currentPage = createPage(pages.length + 1);
      usedHeight = 0;
      return;
    }

    // Block doesn't fit — start new page
    if (usedHeight + blockHeight > contentHeight) {
      // Don't leave a heading orphaned at the bottom of a page
      pages.push(currentPage);
      currentPage = createPage(pages.length + 1);
      usedHeight = 0;
    }

    currentPage.querySelector('.page-inner').appendChild(block);
    usedHeight += blockHeight;
  });

  // Push final page if it has content
  if (usedHeight > 0) {
    pages.push(currentPage);
  }

  // 4. Remove the content stream (blocks have been moved into pages)
  stream.remove();

  // 5. Build spreads from pages
  var spreads = buildSpreads(pages, isMobile);

  // 6. Append spreads to flipbook
  spreads.forEach(function(spread) {
    flipbook.appendChild(spread);
  });

  // 7. Build ToC from heading positions
  buildToC(pages);

  // 8. Initialize navigation
  initNavigation(spreads, pages.length);

  // 9. Initialize Chart.js for visible spread
  initChartsForSpread(0);

  // 10. Show flipbook, hide loader
  document.getElementById('loader').classList.add('hidden');
  flipbook.classList.add('ready');
});
```

### Helper: createPage

```javascript
function createPage(pageNum) {
  var page = document.createElement('div');
  page.className = 'page';
  page.dataset.page = pageNum;
  var inner = document.createElement('div');
  inner.className = 'page-inner';
  page.appendChild(inner);
  var num = document.createElement('div');
  num.className = 'page-number';
  num.textContent = pageNum;
  page.appendChild(num);
  return page;
}
```

### Helper: measureBlock

```javascript
function measureBlock(block, maxHeight) {
  // Use a hidden measuring container with the same width as page-inner
  var measurer = document.getElementById('block-measurer');
  if (!measurer) {
    measurer = document.createElement('div');
    measurer.id = 'block-measurer';
    measurer.style.cssText = 'position:absolute;visibility:hidden;' +
      'width:' + getPageContentWidth() + 'px;' +
      'padding:0;font-size:0.95rem;line-height:1.7;';
    document.body.appendChild(measurer);
  }
  measurer.appendChild(block);
  var height = block.getBoundingClientRect().height;
  measurer.removeChild(block);
  return height;
}
```

### Helper: buildSpreads

```javascript
function buildSpreads(pages, isMobile) {
  var spreads = [];
  if (isMobile) {
    // Single-page mode: each page is its own spread
    pages.forEach(function(page, i) {
      var spread = document.createElement('div');
      spread.className = 'spread' + (i === 0 ? ' active' : '');
      spread.dataset.spread = i;
      page.classList.add('page-single');
      spread.appendChild(page);
      spreads.push(spread);
    });
  } else {
    // Two-page spreads: pair pages [0,1], [2,3], [4,5], ...
    for (var i = 0; i < pages.length; i += 2) {
      var spread = document.createElement('div');
      spread.className = 'spread' + (i === 0 ? ' active' : '');
      spread.dataset.spread = spreads.length;

      var left = pages[i];
      left.classList.add('page-left');
      spread.appendChild(left);

      if (i + 1 < pages.length) {
        var right = pages[i + 1];
        right.classList.add('page-right');
        spread.appendChild(right);
      }

      spreads.push(spread);
    }
  }
  return spreads;
}
```

### Navigation

```javascript
function initNavigation(spreads, totalPages) {
  var current = 0;
  var total = spreads.length;
  var isAnimating = false;

  function goToSpread(index) {
    if (index < 0 || index >= total || index === current || isAnimating) return;
    isAnimating = true;

    var forward = index > current;
    var oldSpread = spreads[current];
    var newSpread = spreads[index];

    // Position next spread underneath
    newSpread.classList.add('next');

    // Trigger page-curl animation
    if (forward) {
      oldSpread.classList.add('turning-forward');
    } else {
      newSpread.classList.add('turning-backward');
    }

    // After animation completes
    setTimeout(function() {
      oldSpread.classList.remove('active', 'turning-forward');
      newSpread.classList.remove('next', 'turning-backward');
      newSpread.classList.add('active');
      current = index;
      isAnimating = false;

      updateCounter();
      updateProgress();
      initChartsForSpread(current);
      updateTocActive();
    }, 800);  // matches --turn-duration
  }

  function updateCounter() {
    var counter = document.getElementById('page-counter');
    var isMobile = window.innerWidth <= 1024;
    if (isMobile) {
      var pageNum = parseInt(spreads[current].querySelector('.page').dataset.page);
      counter.textContent = pageNum + ' of ' + totalPages;
    } else {
      var pages = spreads[current].querySelectorAll('.page');
      var first = pages[0].dataset.page;
      var last = pages[pages.length - 1].dataset.page;
      counter.textContent = first + '-' + last + ' of ' + totalPages;
    }
  }

  function updateProgress() {
    var bar = document.getElementById('progress-bar');
    bar.style.width = ((current + 1) / total * 100) + '%';
  }

  // Keyboard
  document.addEventListener('keydown', function(e) {
    if (e.key === 'ArrowRight' || e.key === ' ' || e.key === 'PageDown') {
      e.preventDefault();
      goToSpread(current + 1);
    } else if (e.key === 'ArrowLeft' || e.key === 'PageUp') {
      e.preventDefault();
      goToSpread(current - 1);
    } else if (e.key === 'Home') {
      e.preventDefault();
      goToSpread(0);
    } else if (e.key === 'End') {
      e.preventDefault();
      goToSpread(total - 1);
    } else if (e.key === 't' || e.key === 'T') {
      toggleToC();
    } else if (e.key === 'f' || e.key === 'F') {
      toggleFullscreen();
    } else if (e.key === '?' || e.key === 'h' || e.key === 'H') {
      toggleHelp();
    } else if (e.key === 'Escape') {
      closeOverlays();
    }
  });

  // Mouse click (right half = next, left half = prev)
  document.getElementById('flipbook').addEventListener('click', function(e) {
    if (e.target.closest('.flipbook-nav, .toc-overlay, .help-overlay, a, button')) return;
    var rect = this.getBoundingClientRect();
    var x = e.clientX - rect.left;
    if (x > rect.width / 2) {
      goToSpread(current + 1);
    } else {
      goToSpread(current - 1);
    }
  });

  // Touch swipe
  var touchStartX = 0;
  document.addEventListener('touchstart', function(e) {
    touchStartX = e.touches[0].clientX;
  }, { passive: true });
  document.addEventListener('touchend', function(e) {
    var dx = e.changedTouches[0].clientX - touchStartX;
    if (Math.abs(dx) > 50) {
      if (dx < 0) goToSpread(current + 1);
      else goToSpread(current - 1);
    }
  }, { passive: true });

  // Button controls
  document.getElementById('btn-prev').addEventListener('click', function() {
    goToSpread(current - 1);
  });
  document.getElementById('btn-next').addEventListener('click', function() {
    goToSpread(current + 1);
  });
  document.getElementById('btn-toc').addEventListener('click', toggleToC);
  document.getElementById('btn-toc-close').addEventListener('click', toggleToC);

  // ToC jump
  document.getElementById('toc-list').addEventListener('click', function(e) {
    var link = e.target.closest('a');
    if (link) {
      e.preventDefault();
      var spreadIdx = parseInt(link.dataset.spread);
      goToSpread(spreadIdx);
      toggleToC();
    }
  });

  // Initialize counter and progress
  updateCounter();
  updateProgress();

  // Expose for ToC
  window._flipbookGoTo = goToSpread;
  window._flipbookCurrent = function() { return current; };
}
```

### Chart.js Lazy Initialization

Charts should only initialize when their page becomes visible. This prevents performance issues with many charts.

```javascript
var chartInitialized = {};

function initChartsForSpread(spreadIndex) {
  var spread = document.querySelectorAll('.spread')[spreadIndex];
  if (!spread) return;
  var canvases = spread.querySelectorAll('canvas[id^="enr-"]');
  canvases.forEach(function(canvas) {
    var id = canvas.id;
    if (chartInitialized[id]) return;
    // Chart init functions are stored in window._chartInits by the agent
    if (window._chartInits && window._chartInits[id]) {
      window._chartInits[id]();
      chartInitialized[id] = true;
    }
  });
}
```

The agent writes chart initialization functions into a registry instead of executing them immediately:

```javascript
window._chartInits = {};
window._chartInits['enr-001'] = function() {
  new Chart(document.getElementById('enr-001'), { /* config */ });
};
window._chartInits['enr-002'] = function() {
  new Chart(document.getElementById('enr-002'), { /* config */ });
};
// ... one entry per chart
```

### ToC Builder

```javascript
function buildToC(pages) {
  var tocList = document.getElementById('toc-list');
  var isMobile = window.innerWidth <= 1024;

  pages.forEach(function(page, pageIndex) {
    var headings = page.querySelectorAll('h2, h3');
    headings.forEach(function(h) {
      var link = document.createElement('a');
      link.href = '#';
      link.className = h.tagName === 'H3' ? 'toc-h3' : 'toc-h2';
      link.dataset.spread = isMobile ? pageIndex : Math.floor(pageIndex / 2);
      link.dataset.page = pageIndex + 1;
      link.innerHTML = h.textContent + ' <span>p.' + (pageIndex + 1) + '</span>';
      tocList.appendChild(link);
    });
  });
}

function updateTocActive() {
  var current = window._flipbookCurrent();
  document.querySelectorAll('.toc-list a').forEach(function(a) {
    a.classList.toggle('active', parseInt(a.dataset.spread) === current);
  });
}
```

### Overlay Toggles

```javascript
function toggleToC() {
  document.getElementById('toc-overlay').classList.toggle('open');
}

function toggleHelp() {
  document.getElementById('help-overlay').classList.toggle('open');
}

function closeOverlays() {
  document.getElementById('toc-overlay').classList.remove('open');
  document.getElementById('help-overlay').classList.remove('open');
}

function toggleFullscreen() {
  if (!document.fullscreenElement) {
    document.documentElement.requestFullscreen().catch(function() {});
  } else {
    document.exitFullscreen();
  }
}
```

## Content Preservation

The same content preservation rules from 06-html-structure.md apply:

- Every paragraph, heading, table, blockquote, list, citation from source appears verbatim
- Validation gates enforce >= 80% word count, matching H2 count, matching citation count
- Enrichments supplement content — they never replace it
- The pagination engine moves blocks between pages; it never discards or modifies content

## Agent Responsibilities (report-html-writer)

When `LAYOUT=flipbook`, the agent writes **scroll-mode HTML** (sidebar + continuous content) with two additions:

1. Wraps the first H2 section in `<!-- FLIPBOOK_COVER_CONTENT -->` / `<!-- /FLIPBOOK_COVER_CONTENT -->` comment markers
2. Writes Chart.js configs into `window._chartInits` lazy-init registry (NOT immediate execution)

The agent does NOT write flipbook CSS, JS, `.block` wrapping, or pagination engine — that deterministic work is handled by the Python post-processor.

The Python post-processor (`--layout flipbook`) handles:
- **Flipbook assembly** — extracts cover content, wraps body elements in `.block` divs, injects flipbook CSS (design tokens + layout + 3D animation + responsive), injects pagination engine JS (measurement + spread building + navigation + ToC + chart lazy init), and assembles the complete flipbook HTML structure
- **Infographic injection** into page 2 (three-tier cascade, same as scroll mode)
- **Content validation** (word count, heading count, citation count)

This division eliminates output token pressure on the agent (~36% reduction) and ensures the JavaScript pagination engine is reproduced exactly (zero drift risk).
- CSS variable resolution in chart configs (var(--color) → hex)
