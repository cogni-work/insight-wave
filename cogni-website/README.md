# cogni-website

Generate multi-page customer websites from insight-wave plugin content.

## Overview

cogni-website assembles content from cogni-portfolio (products, features, propositions, customer narratives) and cogni-marketing (blog posts, articles, whitepapers) into a deployable static website with shared navigation, responsive CSS, and theme-driven styling.

## Prerequisites

- An existing cogni-portfolio project with at least products, features, and propositions
- Optional: cogni-marketing project with content pieces
- A cogni-workspace theme selected via `pick-theme`

## Quick Start

```
/website-setup     # Discover sources, select theme, configure project
/website-plan      # Plan site structure, map pages to content
/website-build     # Generate all pages and assemble the site
/website-preview   # Open in browser and validate
```

## Output

A self-contained static site folder at `output/website/` that can be:
- Opened locally via `index.html`
- Deployed to Netlify, Vercel, S3, or any static hosting
- Served via `python3 -m http.server` for local testing

## Content Sources

| Source | Pages Generated |
|--------|----------------|
| Portfolio products | Products index + detail pages |
| Portfolio propositions | Solutions page |
| Portfolio communicate | Homepage, about, case studies |
| Marketing thought-leadership | Blog posts |
| Marketing demand-generation | Blog posts |
| Marketing lead-generation | Landing pages |

## Features

- Theme-driven CSS via cogni-workspace design variables
- Pencil MCP hero rendering for homepage (AI-generated images)
- Responsive design (desktop + mobile breakpoints)
- Shared navigation with header, footer, and mobile menu
- SEO meta tags and sitemap.xml
- German language primary, bilingual planned
