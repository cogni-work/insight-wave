---
library_id: navigation-patterns
version: 1.0.0
created: 2026-03-27
---

# Navigation Patterns Library

Shared HTML patterns for site-wide navigation elements. The `site-assembler` agent generates these as partials that every page includes.

---

## Header Navigation

The header is fixed at the top with logo, nav links, and a CTA button. It uses a mobile hamburger menu below 768px.

```html
<header class="site-header" role="banner">
  <div class="container site-header__inner">
    <a href="{base_url}" class="site-header__logo">
      <span class="site-header__logo-text">{logo_text}</span>
    </a>

    <nav class="site-nav" role="navigation" aria-label="Hauptnavigation">
      <ul class="site-nav__list">
        <li class="site-nav__item">
          <a href="{href}" class="site-nav__link {active_class}">{label}</a>
        </li>
        <li class="site-nav__item site-nav__item--has-children">
          <a href="{href}" class="site-nav__link">{label}</a>
          <ul class="site-nav__dropdown">
            <li><a href="{child_href}" class="site-nav__dropdown-link">{child_label}</a></li>
            <!-- repeat -->
          </ul>
        </li>
        <!-- repeat per nav item -->
      </ul>
    </nav>

    <a href="{cta_href}" class="btn btn--primary site-header__cta">{cta_text}</a>

    <button class="site-header__mobile-toggle" aria-label="Menü öffnen" aria-expanded="false">
      <span class="hamburger"></span>
    </button>
  </div>
</header>
```

### Active State

Add `site-nav__link--active` to the nav link matching the current page. For dropdown parents, add it to the parent link when any child is active.

### Mobile Menu

Below 768px:
- Hide `.site-nav` and `.site-header__cta` by default
- Show `.site-header__mobile-toggle`
- On toggle click: show `.site-nav` as vertical stack overlay
- Include CTA at bottom of mobile menu

### JavaScript (inline, minimal)

```html
<script>
  document.querySelector('.site-header__mobile-toggle')?.addEventListener('click', function() {
    const nav = document.querySelector('.site-nav');
    const expanded = this.getAttribute('aria-expanded') === 'true';
    this.setAttribute('aria-expanded', !expanded);
    nav.classList.toggle('site-nav--open');
  });
</script>
```

---

## Footer

The footer contains column links, company info, and copyright.

```html
<footer class="site-footer" role="contentinfo">
  <div class="container">
    <div class="site-footer__grid">
      <div class="site-footer__column">
        <h3 class="site-footer__heading">{column_title}</h3>
        <ul class="site-footer__links">
          <li><a href="{href}">{label}</a></li>
          <!-- repeat -->
        </ul>
      </div>
      <!-- repeat per column -->

      <div class="site-footer__column site-footer__column--brand">
        <span class="site-footer__logo">{logo_text}</span>
        <p class="site-footer__tagline">{tagline}</p>
      </div>
    </div>

    <div class="site-footer__bottom">
      <p class="site-footer__copyright">&copy; {year} {company_name}. Alle Rechte vorbehalten.</p>
    </div>
  </div>
</footer>
```

### Footer Columns

Typical structure for a company website:

| Column | Links |
|--------|-------|
| Produkte | Product detail pages |
| Lösungen | Solutions page, key market pages |
| Unternehmen | Über uns, Kontakt, Karriere |
| Ressourcen | Blog, Fallstudien, Downloads |

---

## Breadcrumbs

Used on all interior pages (not homepage).

```html
<nav class="breadcrumb" aria-label="Breadcrumb">
  <ol class="breadcrumb__list">
    <li class="breadcrumb__item"><a href="{base_url}">Startseite</a></li>
    <li class="breadcrumb__item"><a href="{parent_href}">{parent_label}</a></li>
    <li class="breadcrumb__item breadcrumb__item--current" aria-current="page">{current_label}</li>
  </ol>
</nav>
```

### Breadcrumb Rules

- Always start with "Startseite" (or "Home" for EN)
- Maximum 3 levels deep
- Current page is plain text (no link), marked with `aria-current="page"`
- Use `breadcrumb--light` variant on dark hero backgrounds

---

## CSS Requirements

The `site-assembler` generates these styles in `css/style.css`:

### Header

```css
.site-header {
  position: sticky;
  top: 0;
  z-index: 100;
  background: var(--background);
  border-bottom: 1px solid var(--border);
  padding: 0 1.5rem;
  height: 72px;
}

.site-header__inner {
  display: flex;
  align-items: center;
  justify-content: space-between;
  height: 100%;
}

.site-header__logo-text {
  font-family: var(--font-primary);
  font-weight: bold;
  font-size: 1.25rem;
  color: var(--text);
  text-decoration: none;
}

.site-nav__list {
  display: flex;
  gap: 2rem;
  list-style: none;
  margin: 0;
  padding: 0;
}

.site-nav__link {
  font-family: var(--font-body);
  font-size: 0.9375rem;
  color: var(--text-muted);
  text-decoration: none;
  transition: color 0.2s;
}

.site-nav__link:hover,
.site-nav__link--active {
  color: var(--accent);
}

/* Dropdown */
.site-nav__item--has-children {
  position: relative;
}

.site-nav__dropdown {
  display: none;
  position: absolute;
  top: 100%;
  left: 0;
  background: var(--background);
  border: 1px solid var(--border);
  border-radius: var(--radius);
  padding: 0.5rem 0;
  min-width: 200px;
  box-shadow: var(--shadow-md);
}

.site-nav__item--has-children:hover .site-nav__dropdown {
  display: block;
}

/* Mobile */
.site-header__mobile-toggle {
  display: none;
}

@media (max-width: 768px) {
  .site-nav, .site-header__cta { display: none; }
  .site-header__mobile-toggle { display: block; }
  .site-nav--open {
    display: flex;
    flex-direction: column;
    position: absolute;
    top: 72px;
    left: 0;
    right: 0;
    background: var(--background);
    border-bottom: 1px solid var(--border);
    padding: 1rem;
  }
  .site-nav--open .site-nav__list {
    flex-direction: column;
    gap: 0.5rem;
  }
}
```

### Footer

```css
.site-footer {
  background: var(--surface-dark);
  color: var(--surface-dark-text, #fff);
  padding: 4rem 0 2rem;
}

.site-footer__grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
  gap: 2rem;
  margin-bottom: 3rem;
}

.site-footer__heading {
  font-family: var(--font-primary);
  font-size: 1rem;
  font-weight: bold;
  margin-bottom: 1rem;
}

.site-footer__links {
  list-style: none;
  padding: 0;
  margin: 0;
}

.site-footer__links a {
  color: var(--surface-dark-muted, #ccc);
  text-decoration: none;
  font-size: 0.875rem;
  line-height: 2;
}

.site-footer__links a:hover {
  color: #fff;
}

.site-footer__bottom {
  border-top: 1px solid rgba(255,255,255,0.1);
  padding-top: 1.5rem;
  text-align: center;
}

.site-footer__copyright {
  font-size: 0.8125rem;
  color: var(--surface-dark-muted, #999);
}
```

### Breadcrumbs

```css
.breadcrumb__list {
  display: flex;
  gap: 0.5rem;
  list-style: none;
  padding: 0;
  margin: 0 0 1rem;
  font-size: 0.875rem;
}

.breadcrumb__item + .breadcrumb__item::before {
  content: "›";
  margin-right: 0.5rem;
  color: var(--text-muted);
}

.breadcrumb__item a {
  color: var(--text-muted);
  text-decoration: none;
}

.breadcrumb__item a:hover {
  color: var(--accent);
}

.breadcrumb__item--current {
  color: var(--text);
}

.breadcrumb--light .breadcrumb__item a,
.breadcrumb--light .breadcrumb__item::before {
  color: var(--surface-dark-muted, #ccc);
}

.breadcrumb--light .breadcrumb__item--current {
  color: #fff;
}
```
