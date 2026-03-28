---
library_id: page-templates
version: 1.0.0
created: 2026-03-27
---

# Page Templates Library

HTML structure patterns for each page type in cogni-website. The `page-generator` agent uses these patterns to produce semantic, responsive HTML pages that share a common CSS stylesheet.

Every page follows this outer shell:

```html
<!DOCTYPE html>
<html lang="de">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="{meta_description}">
  <title>{page_title} — {site_title}</title>
  <link rel="stylesheet" href="{css_path}">
  {google_fonts_import}
</head>
<body>
  {navigation_header}
  <main>
    {page_content}
  </main>
  {navigation_footer}
</body>
</html>
```

**Path resolution:** `{css_path}` is relative to the page's location. For `pages/products/cloud.html` it would be `../../css/style.css`.

---

## 1. Home Page (`home`)

The homepage is the only page that may use Pencil MCP for its hero section. All other sections are standard HTML.

### Sections

1. **Hero** (dark background, full-width)
   - Background: gradient or AI-generated image (via hero-renderer agent)
   - Content: headline (h1), subline (p), primary CTA button
   - Overlay if image background: semi-transparent dark layer

2. **Value Propositions** (light background)
   - 3-4 cards in a CSS grid row
   - Each card: icon placeholder, headline (h3), short description
   - Source: top propositions from portfolio synthesize

3. **Product Highlights** (light-alt background)
   - 2-3 product cards with image placeholder, name, description, link
   - Source: products from portfolio

4. **Stats Row** (dark background)
   - 3-4 metric cards: large number, label, optional context
   - Source: market sizing data, customer counts, or solution metrics

5. **CTA Section** (accent background)
   - Headline, supporting text, primary + secondary CTA buttons
   - Link to contact page

### HTML Pattern

```html
<section class="hero hero--dark">
  <div class="hero__overlay"></div>
  <div class="hero__content container">
    <p class="section-label">{section_label}</p>
    <h1 class="hero__headline">{headline}</h1>
    <p class="hero__subline">{subline}</p>
    <a href="{cta_href}" class="btn btn--primary btn--lg">{cta_text}</a>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <h2 class="section__headline">{headline}</h2>
    <div class="card-grid card-grid--3">
      <div class="card">
        <div class="card__icon">{icon}</div>
        <h3 class="card__headline">{card_headline}</h3>
        <p class="card__body">{card_body}</p>
      </div>
      <!-- repeat -->
    </div>
  </div>
</section>

<section class="section section--light-alt">
  <div class="container">
    <h2 class="section__headline">{headline}</h2>
    <div class="card-grid card-grid--2">
      <article class="product-card">
        <div class="product-card__image"></div>
        <h3 class="product-card__name">{name}</h3>
        <p class="product-card__description">{description}</p>
        <a href="{detail_href}" class="btn btn--outline">{detail_cta}</a>
      </article>
      <!-- repeat -->
    </div>
  </div>
</section>

<section class="section section--dark stats-row">
  <div class="container">
    <div class="stats-grid">
      <div class="stat">
        <span class="stat__number">{number}</span>
        <span class="stat__label">{label}</span>
      </div>
      <!-- repeat 3-4 -->
    </div>
  </div>
</section>

<section class="section section--accent cta-section">
  <div class="container">
    <h2 class="cta-section__headline">{headline}</h2>
    <p class="cta-section__body">{body}</p>
    <div class="cta-section__buttons">
      <a href="{primary_href}" class="btn btn--white btn--lg">{primary_cta}</a>
      <a href="{secondary_href}" class="btn btn--outline-white">{secondary_cta}</a>
    </div>
  </div>
</section>
```

---

## 2. About Page (`about`)

### Sections

1. **Page Header** (light, with breadcrumb)
2. **Company Story** — narrative from portfolio company context
3. **Mission/Vision** — short statement block
4. **Timeline** (optional) — company milestones
5. **CTA** — contact or career link

### HTML Pattern

```html
<section class="page-header">
  <div class="container">
    <nav class="breadcrumb">{breadcrumb}</nav>
    <h1>{page_title}</h1>
    <p class="page-header__subtitle">{subtitle}</p>
  </div>
</section>

<section class="section section--light">
  <div class="container content-narrow">
    <h2>{story_headline}</h2>
    <div class="prose">{story_body}</div>
  </div>
</section>

<section class="section section--light-alt">
  <div class="container">
    <blockquote class="mission-quote">
      <p>{mission_text}</p>
    </blockquote>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <h2>{timeline_headline}</h2>
    <ol class="timeline">
      <li class="timeline__item">
        <span class="timeline__year">{year}</span>
        <h3 class="timeline__title">{title}</h3>
        <p class="timeline__description">{description}</p>
      </li>
      <!-- repeat -->
    </ol>
  </div>
</section>
```

---

## 3. Products Index (`products`)

### Sections

1. **Page Header** with breadcrumb
2. **Product Grid** — all products as cards with positioning, link to detail

### HTML Pattern

```html
<section class="page-header">
  <div class="container">
    <nav class="breadcrumb">{breadcrumb}</nav>
    <h1>{page_title}</h1>
    <p class="page-header__subtitle">{subtitle}</p>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <div class="card-grid card-grid--3">
      <article class="product-card product-card--featured">
        <div class="product-card__image"></div>
        <span class="product-card__badge">{maturity}</span>
        <h2 class="product-card__name">{name}</h2>
        <p class="product-card__positioning">{positioning}</p>
        <p class="product-card__description">{description}</p>
        <a href="{detail_href}" class="btn btn--primary">{cta}</a>
      </article>
      <!-- repeat per product -->
    </div>
  </div>
</section>
```

---

## 4. Product Detail (`product-detail`)

### Sections

1. **Product Hero** (dark) — product name, positioning, key benefit
2. **Features** — feature cards from the product's feature list
3. **Benefits** (alternating) — proposition DOES/MEANS statements per market
4. **Pricing/Packages** (optional) — if packages exist for this product
5. **CTA** — contact or demo request

### HTML Pattern

```html
<section class="hero hero--dark hero--compact">
  <div class="container">
    <nav class="breadcrumb breadcrumb--light">{breadcrumb}</nav>
    <h1 class="hero__headline">{product_name}</h1>
    <p class="hero__subline">{positioning}</p>
    <a href="#contact" class="btn btn--primary btn--lg">{cta}</a>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <h2 class="section__headline">{features_headline}</h2>
    <div class="card-grid card-grid--3">
      <div class="feature-card">
        <h3 class="feature-card__name">{feature_name}</h3>
        <p class="feature-card__is">{is_statement}</p>
      </div>
      <!-- repeat per feature -->
    </div>
  </div>
</section>

<section class="section section--light-alt">
  <div class="container">
    <h2 class="section__headline">{benefits_headline}</h2>
    <div class="benefits-list">
      <div class="benefit-row">
        <div class="benefit-row__content">
          <h3>{does_headline}</h3>
          <p class="benefit-row__does">{does_statement}</p>
          <p class="benefit-row__means">{means_statement}</p>
        </div>
      </div>
      <!-- repeat per proposition -->
    </div>
  </div>
</section>

<section class="section section--light" id="pricing">
  <div class="container">
    <h2 class="section__headline">{pricing_headline}</h2>
    <div class="pricing-grid">
      <div class="pricing-card">
        <h3 class="pricing-card__tier">{tier_name}</h3>
        <p class="pricing-card__price">{price_label}</p>
        <ul class="pricing-card__features">
          <li>{included_feature}</li>
          <!-- repeat -->
        </ul>
        <a href="#contact" class="btn btn--primary">{cta}</a>
      </div>
      <!-- repeat per tier -->
    </div>
  </div>
</section>
```

---

## 5. Solutions Page (`solutions`)

### Sections

1. **Page Header**
2. **Solution Cards** grouped by market or by problem domain
3. **CTA**

### HTML Pattern

```html
<section class="page-header">
  <div class="container">
    <nav class="breadcrumb">{breadcrumb}</nav>
    <h1>{page_title}</h1>
    <p class="page-header__subtitle">{subtitle}</p>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <h2 class="section__headline">{market_name}</h2>
    <div class="solution-grid">
      <article class="solution-card">
        <h3 class="solution-card__name">{solution_name}</h3>
        <p class="solution-card__is">{is_statement}</p>
        <p class="solution-card__does">{does_statement}</p>
        <div class="solution-card__meta">
          <span class="solution-card__type">{solution_type}</span>
          <span class="solution-card__pricing">{pricing_range}</span>
        </div>
        <a href="{detail_href}" class="btn btn--outline">{cta}</a>
      </article>
      <!-- repeat per solution in market -->
    </div>
  </div>
</section>
<!-- repeat per market group -->
```

---

## 6. Blog Index (`blog-index`)

### Sections

1. **Page Header**
2. **Featured Post** (large card, latest or pinned)
3. **Post Grid** — cards with excerpt, date, category, read-more link

### HTML Pattern

```html
<section class="page-header">
  <div class="container">
    <nav class="breadcrumb">{breadcrumb}</nav>
    <h1>{page_title}</h1>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <article class="post-card post-card--featured">
      <div class="post-card__image"></div>
      <div class="post-card__content">
        <span class="post-card__category">{category}</span>
        <h2 class="post-card__title"><a href="{post_href}">{title}</a></h2>
        <p class="post-card__excerpt">{excerpt}</p>
        <time class="post-card__date" datetime="{iso_date}">{display_date}</time>
      </div>
    </article>
  </div>
</section>

<section class="section section--light-alt">
  <div class="container">
    <div class="card-grid card-grid--3">
      <article class="post-card">
        <div class="post-card__image"></div>
        <span class="post-card__category">{category}</span>
        <h2 class="post-card__title"><a href="{post_href}">{title}</a></h2>
        <p class="post-card__excerpt">{excerpt}</p>
        <time class="post-card__date" datetime="{iso_date}">{display_date}</time>
      </article>
      <!-- repeat per post -->
    </div>
  </div>
</section>
```

---

## 7. Blog Post (`blog-post`)

### Sections

1. **Article Header** — title, date, category, reading time
2. **Article Body** — rendered from markdown content
3. **Author/Source** (optional)
4. **Related Posts** (optional)
5. **CTA** — subscribe or contact

### HTML Pattern

```html
<article class="article">
  <header class="article__header">
    <div class="container content-narrow">
      <nav class="breadcrumb">{breadcrumb}</nav>
      <span class="article__category">{category}</span>
      <h1 class="article__title">{title}</h1>
      <div class="article__meta">
        <time datetime="{iso_date}">{display_date}</time>
        <span class="article__reading-time">{reading_time} Min. Lesezeit</span>
      </div>
    </div>
  </header>

  <div class="article__body">
    <div class="container content-narrow prose">
      {rendered_markdown_body}
    </div>
  </div>

  <footer class="article__footer">
    <div class="container content-narrow">
      <div class="article__source">
        <p>{source_attribution}</p>
      </div>
    </div>
  </footer>
</article>

<section class="section section--light-alt">
  <div class="container">
    <h2 class="section__headline">{related_headline}</h2>
    <div class="card-grid card-grid--3">
      <!-- post-card elements -->
    </div>
  </div>
</section>
```

---

## 8. Case Studies (`case-studies`)

### Sections

1. **Page Header**
2. **Case Study Cards** — from portfolio-communicate customer narratives

### HTML Pattern

```html
<section class="page-header">
  <div class="container">
    <nav class="breadcrumb">{breadcrumb}</nav>
    <h1>{page_title}</h1>
    <p class="page-header__subtitle">{subtitle}</p>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <div class="card-grid card-grid--2">
      <article class="case-card">
        <div class="case-card__image"></div>
        <span class="case-card__market">{market_name}</span>
        <h2 class="case-card__title">{narrative_title}</h2>
        <p class="case-card__excerpt">{first_paragraph}</p>
        <a href="{detail_href}" class="btn btn--outline">{cta}</a>
      </article>
      <!-- repeat per customer narrative -->
    </div>
  </div>
</section>
```

---

## 9. Contact Page (`contact`)

### Sections

1. **Page Header**
2. **Contact Info + Form Placeholder** — two-column layout
3. **Map Embed** (optional placeholder)

### HTML Pattern

```html
<section class="page-header">
  <div class="container">
    <nav class="breadcrumb">{breadcrumb}</nav>
    <h1>{page_title}</h1>
    <p class="page-header__subtitle">{subtitle}</p>
  </div>
</section>

<section class="section section--light">
  <div class="container">
    <div class="contact-grid">
      <div class="contact-info">
        <h2>{info_headline}</h2>
        <address>
          <p>{company_name}</p>
          <p>{address}</p>
          <p><a href="mailto:{email}">{email}</a></p>
          <p><a href="tel:{phone}">{phone}</a></p>
        </address>
      </div>
      <div class="contact-form">
        <h2>{form_headline}</h2>
        <form class="form" action="#" method="post">
          <div class="form__field">
            <label for="name">{label_name}</label>
            <input type="text" id="name" name="name" required>
          </div>
          <div class="form__field">
            <label for="email">{label_email}</label>
            <input type="email" id="email" name="email" required>
          </div>
          <div class="form__field">
            <label for="message">{label_message}</label>
            <textarea id="message" name="message" rows="5" required></textarea>
          </div>
          <button type="submit" class="btn btn--primary btn--lg">{submit_text}</button>
        </form>
      </div>
    </div>
  </div>
</section>
```

---

## CSS Class Reference

All page templates use a shared set of CSS classes defined in `css/style.css`:

### Layout
- `.container` — max-width 1200px, centered, horizontal padding
- `.content-narrow` — max-width 720px for readable prose
- `.card-grid` — CSS grid (`.card-grid--2`, `.card-grid--3`, `.card-grid--4`)

### Sections
- `.section` — standard section with vertical padding
- `.section--light` — `var(--background)` background
- `.section--light-alt` — `var(--background-alt)` background
- `.section--dark` — `var(--surface-dark)` background, light text
- `.section--accent` — `var(--primary)` background, white text

### Buttons
- `.btn` — base button styles
- `.btn--primary` — primary color background
- `.btn--outline` — bordered, transparent background
- `.btn--white` — white background (on dark/accent sections)
- `.btn--outline-white` — white border (on dark/accent sections)
- `.btn--lg` — larger padding and font

### Typography
- `.prose` — long-form content styling (paragraphs, lists, headings)
- `.section-label` — uppercase, small, bold label
- `.section__headline` — h2-level section title
- `.hero__headline` — large hero h1

### Components
- `.hero` — full-width hero with content overlay
- `.card` — generic content card
- `.stat` — metric display (number + label)
- `.breadcrumb` — navigation breadcrumb
- `.timeline` — ordered milestone list
