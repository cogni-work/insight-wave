---
library_id: legal-pages
version: 1.0.0
created: 2026-04-08
---

# Legal Pages Library

HTML rendering patterns for the three legal page types produced by the `website-legal` skill: `legal-imprint`, `legal-privacy`, and `legal-cookies`. The `page-generator` agent reads this file when it encounters a page with one of these types.

Legal pages are deliberately plain: a centered single-column layout, generous line height, no hero, no CTA, no decorative imagery. The content has to be legible and printable, not "engaging".

---

## Page types

| Type | Slug pattern (DE/AT/CH) | Slug pattern (EU) | Source |
|------|------------------------|-------------------|--------|
| `legal-imprint` | `pages/impressum` | `pages/legal-notice` | `content/legal/impressum.md` (or `legal-notice.md`) |
| `legal-privacy` | `pages/datenschutz` | `pages/privacy-policy` | `content/legal/datenschutz.md` (or `privacy-policy.md`) |
| `legal-cookies` | `pages/cookies` | `pages/cookies` | `content/legal/cookies.md` |

All three are marked `footer_only: true` in `website-plan.json` — they appear in the footer legal column but not in the primary navigation.

---

## HTML pattern

Every legal page uses the same two sections: `legal-header` and `legal-body`.

```html
<!DOCTYPE html>
<html lang="{language}">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <meta name="description" content="{meta_description}">
  <meta name="robots" content="index, follow">
  <title>{page_title} — {site_title}</title>
  <link rel="stylesheet" href="{css_path}">
</head>
<body>
  {navigation_header}

  <main class="legal-page">
    <div class="container container--narrow">
      <nav class="breadcrumb" aria-label="Breadcrumb">
        <ol class="breadcrumb__list">
          <li class="breadcrumb__item"><a href="{base_url}">{home_label}</a></li>
          <li class="breadcrumb__item breadcrumb__item--current" aria-current="page">{page_title}</li>
        </ol>
      </nav>

      <header class="legal-header">
        <h1 class="legal-header__title">{page_title}</h1>
        <p class="legal-header__updated">Stand: {generated_at_human}</p>
      </header>

      <article class="legal-body prose">
        {converted_markdown_body}
      </article>
    </div>
  </main>

  {navigation_footer}
  {cookie_notice_partial}
  {mobile_menu_script}
</body>
</html>
```

### Markdown-to-HTML conversion rules

The legal markdown source uses standard markdown — headings, paragraphs, lists, tables, links. Convert as follows:

- `# Title` → omit (the H1 is rendered from `page_title` in the legal-header section instead)
- `## Section` → `<h2>`
- `### Subsection` → `<h3>`
- Paragraphs → `<p>`
- Bullet lists → `<ul><li>`
- Tables → `<table class="legal-table">` with `<thead>` and `<tbody>`
- Links → `<a href>` (preserve `mailto:` and external URLs)
- The horizontal rule (`---`) and trailing italic line (`*Stand: ...*`) at the end of each template → omit (the date is in the legal-header instead)
- The frontmatter block (`--- ... ---`) → omit (used only for `slug`/`title`/`language` metadata)
- Any literal `«TODO: ...»` markers from unfilled placeholders → wrap in `<mark class="legal-todo">«TODO: ...»</mark>` so they are visually obvious

---

## CSS classes

The `site-assembler` agent adds these classes to `css/style.css` when at least one legal page exists in the plan.

```css
.legal-page {
  padding: 3rem 0 5rem;
}

.container--narrow {
  max-width: 720px;
}

.legal-header {
  margin-bottom: 2.5rem;
  padding-bottom: 1.5rem;
  border-bottom: 1px solid var(--border);
}

.legal-header__title {
  font-family: var(--font-primary);
  font-size: 2.25rem;
  line-height: 1.2;
  margin: 0 0 0.5rem;
  color: var(--text);
}

.legal-header__updated {
  font-size: 0.875rem;
  color: var(--text-muted);
  margin: 0;
}

.legal-body h2 {
  font-family: var(--font-primary);
  font-size: 1.5rem;
  line-height: 1.3;
  margin: 2.5rem 0 1rem;
  color: var(--text);
}

.legal-body h3 {
  font-family: var(--font-primary);
  font-size: 1.125rem;
  margin: 2rem 0 0.75rem;
  color: var(--text);
}

.legal-body p,
.legal-body li {
  font-family: var(--font-body);
  font-size: 1rem;
  line-height: 1.7;
  color: var(--text);
}

.legal-body ul,
.legal-body ol {
  padding-left: 1.5rem;
  margin: 1rem 0 1.5rem;
}

.legal-body a {
  color: var(--accent);
  text-decoration: underline;
}

.legal-table {
  width: 100%;
  border-collapse: collapse;
  margin: 1.5rem 0;
  font-size: 0.9375rem;
}

.legal-table th,
.legal-table td {
  text-align: left;
  padding: 0.625rem 0.75rem;
  border-bottom: 1px solid var(--border);
}

.legal-table th {
  font-weight: 600;
  color: var(--text);
  background: var(--surface);
}

.legal-todo {
  background: #fff3cd;
  color: #664d03;
  padding: 0.125rem 0.375rem;
  border-radius: 3px;
  font-family: var(--font-mono);
  font-size: 0.875rem;
}

@media (max-width: 768px) {
  .legal-header__title {
    font-size: 1.75rem;
  }
  .legal-page {
    padding: 2rem 0 3rem;
  }
}
```

---

## Cookie notice partial

Static, non-interactive bottom bar shown on every page (not only legal pages). The `site-assembler` agent writes it to `output/website/.partials/cookie-notice.html` and the `page-generator` includes it in every rendered page right before the closing `</body>`.

```html
<aside class="cookie-notice" role="complementary" aria-label="Cookie-Hinweis">
  <div class="cookie-notice__inner container">
    <p class="cookie-notice__text">
      Diese Website verwendet ausschließlich technisch notwendige Cookies. Weitere Informationen finden Sie in unserem
      <a href="/pages/cookies.html" class="cookie-notice__link">Cookie-Hinweis</a>.
    </p>
  </div>
</aside>
```

**Language selection rule** — `site-assembler` MUST pick the wording deterministically:

1. If `website-project.json` `language` is `de`, use the German text above.
2. If `language` is `en`, use the English text below.
3. If `language` is unset or any other value, fall back to `legal_config.jurisdiction`: `de` / `at` / `ch` → German, `eu` → English.

English variant:

```html
<aside class="cookie-notice" role="complementary" aria-label="Cookie notice">
  <div class="cookie-notice__inner container">
    <p class="cookie-notice__text">
      This website uses only strictly necessary cookies. For more information, see our
      <a href="/pages/cookies.html" class="cookie-notice__link">Cookie Notice</a>.
    </p>
  </div>
</aside>
```

CSS:

```css
.cookie-notice {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: var(--surface-dark);
  color: var(--surface-dark-text, #fff);
  padding: 0.75rem 0;
  font-size: 0.875rem;
  z-index: 50;
  border-top: 1px solid rgba(255,255,255,0.1);
}

.cookie-notice__inner {
  display: flex;
  align-items: center;
  justify-content: center;
}

.cookie-notice__text {
  margin: 0;
  text-align: center;
  line-height: 1.5;
}

.cookie-notice__link {
  color: #fff;
  text-decoration: underline;
}

@media (max-width: 768px) {
  .cookie-notice {
    padding: 0.625rem 0.75rem;
  }
  .cookie-notice__text {
    font-size: 0.8125rem;
  }
}
```

The cookie notice is **static** — it has no dismiss button, no localStorage, no JavaScript. It is correct only for sites that set strictly necessary cookies. If the site enables analytics or marketing cookies, the user must replace this partial with a real consent manager — that is out of scope for the current plugin.

---

## Footer legal column

When the plan contains a `legal_links` array, the `site-assembler` adds a third footer column titled "Rechtliches" (DE/AT/CH) or "Legal" (EU) with the legal page links. See `libraries/navigation-patterns.md` for the footer pattern; the legal column reuses the standard `site-footer__column` markup.
