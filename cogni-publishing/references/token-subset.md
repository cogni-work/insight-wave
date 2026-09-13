# Supported token subset

A theme's `tokens/*.json` files are its one authoritative representation of design variables. `scripts/generate-tokens-css.py` compiles them; `tokens.css` and `tokens.resolved.json` are projections generated from them and never edited by hand. This page lists exactly what the compiler accepts.

**This is not full DTCG support.** The format borrows a bounded subset of the W3C Design Tokens Community Group format — its alias syntax and its token-object members — because that is what theme authors and design tools already write. Everything outside the subset below is either rejected with a named finding or skipped and reported; nothing outside it is silently half-supported.

## Files

Seven canonical files, compiled in this order; each is optional:

| File | Holds |
|------|-------|
| `colors.json` | colour primitives |
| `typography.json` | font families, sizes, line heights, tracking |
| `spacing.json` | spacing scale |
| `radii.json` | corner radii |
| `shadows.json` | shadow values, as CSS strings |
| `motion.json` | easing curves and durations, as CSS strings |
| `semantic.json` | role tokens (`fg`, `bg`, `surface`, …), usually aliases to primitives |

Each file is one flat JSON object mapping a key to a token. Keys use letters, digits, hyphens and underscores.

## Token shapes

| Shape | Example | Meaning |
|-------|---------|---------|
| Literal | `"ink": "#111111"`, `"3": "12px"`, `"weight": 700` | A string or number, emitted as written |
| Alias | `"fg": "{colors.ink}"` | A reference to another token, written exactly `{<file>.<key>}` over the seven files above |
| Token object | `"fg": {"$value": "{colors.ink}", "$type": "color"}` | A DTCG token; `$value` is a literal or an alias |

A token object may carry only these members: `$value` (required), `$type`, and the ignored `$description`, `$extensions` and `$deprecated`. The same three ignored members are also allowed at the root of a file.

**Supported $type values:** `color`, `dimension`, `fontFamily`, `fontWeight`, `duration`, `number`

`$type` is informational: the compiler records the type the author declared but does not re-validate the value's syntax against it.

## How aliases compile

An alias stays an alias in `tokens.css`, so the role survives into the output:

```css
--colors-ink: #111111;
--semantic-text: var(--colors-ink);
--semantic-fg: var(--semantic-text);
```

A chain may pass through any number of aliases; each link points at its immediate target, never collapsed onto the final value. For consumers that cannot evaluate `var()` — a PPTX renderer, a colour audit — `tokens.resolved.json` (or `generate-tokens-css.py --format resolved-json`) carries every token resolved to its literal, together with the alias map (`"semantic.fg": "semantic.text"`). It is written whenever the theme holds at least one alias.

## Failures

These fail the compile — and so `generate-tokens-css.py`, `validate-theme-manifest.py` and the bundle importer — with exit 1 and an envelope whose `data` is the finding alone (`code`, `token`, `reference`); nothing is written:

| Code | Cause |
|------|-------|
| `alias-cycle` | An alias chain returns to a token it already visited |
| `unresolved-reference` | An alias names a token no file defines |
| `malformed-alias` | A `{…}` value that is not exactly `{<file>.<key>}` |
| `unsupported-construct` | A required construct outside the subset: a composite `$value` (object or array), a `$type` outside the list above, an unknown token-object member, a DTCG group (an object with `$`-members but no `$value`), a root-level member other than the three ignored ones, or an alias into a file that is not one of the seven |

## Skipped and reported

Legacy shapes the flat-map generator always skipped stay skipped, so existing themes need no upgrade: a plain nested object without `$value`, a boolean, a null, an array, or a file that is not a JSON object. They are listed under `skipped` (compiler) or `tokens_skipped` (validator) rather than dropped in silence.

## Outside the subset

Not supported, by design: DTCG groups and `$type` inheritance, composite types (`shadow`, `typography`, `border`, `transition`, `gradient`, `strokeStyle`, `cubicBezier` as an array), references to a token's sub-property, references across files outside the seven canonical ones, and `$extends`. Write composite values as CSS strings instead — a shadow is `"0 1px 3px rgba(0,0,0,0.04)"`, an easing curve `"cubic-bezier(0.2, 0, 0, 1)"`.
