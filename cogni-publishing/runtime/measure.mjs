// Offline measurement of one design-render HTML page with the pinned playwright-core.
//
// Invoked only by scripts/design-render.py (`measure`, `render --measure`) with the interpreter the
// provisioning record names:  node measure.mjs <runtime-root> <index.html> <width> <height>
// playwright-core is resolved from <runtime-root>/node_modules and its browser build from
// PLAYWRIGHT_BROWSERS_PATH, never from a global install. Every request other than the page itself is
// aborted and reported, so a page that needs anything from outside itself shows up as a blocked request.
// Prints one JSON report on stdout: DOM geometry per unit and slot, clipped copy, and the platform
// fonts the browser actually used for copy.

import { createRequire } from 'node:module';
import path from 'node:path';
import { pathToFileURL } from 'node:url';

const [root, htmlPath, widthArg, heightArg] = process.argv.slice(2);
const require = createRequire(path.join(root, 'package.json'));
const { chromium } = require('playwright-core');

const viewport = { width: Number(widthArg), height: Number(heightArg) };
const documentUrl = pathToFileURL(path.resolve(htmlPath)).href;
const blocked = [];
const failed = [];

const browser = await chromium.launch({ headless: true });
try {
  const context = await browser.newContext({ viewport, deviceScaleFactor: 1, offline: true });
  await context.route('**/*', (route) => {
    const url = route.request().url();
    if (url === documentUrl) return route.continue();
    blocked.push(url);
    return route.abort('blockedbyclient');
  });
  const page = await context.newPage();
  page.on('requestfailed', (request) => {
    const url = request.url();
    if (url !== documentUrl && !blocked.includes(url)) failed.push(url);
  });
  await page.goto(documentUrl, { waitUntil: 'load' });
  // A face the page embeds loads from its own data URI; measure once every face has loaded, so the
  // geometry and the platform fonts below are those of the face the page is actually set in.
  await page.evaluate(() => document.fonts.ready.then(() => true));

  const layout = await page.evaluate(() => {
    const box = (el) => {
      const b = el.getBoundingClientRect();
      const round = (v) => Math.round(v * 100) / 100;
      return { x: round(b.x + window.scrollX), y: round(b.y + window.scrollY), width: round(b.width), height: round(b.height) };
    };
    const units = [...document.querySelectorAll('section[data-unit]')].map((el) => ({
      unit: el.dataset.unit,
      box: box(el),
      slots: [...el.querySelectorAll('[data-slot]')].map((slot) => ({ slot: slot.dataset.slot, box: box(slot) })),
    }));
    const clipped = [];
    for (const el of document.querySelectorAll('[data-copy]')) {
      const b = el.getBoundingClientRect();
      let hidden = b.width === 0 || b.height === 0;
      for (let node = el; node && node.nodeType === 1 && !hidden; node = node.parentElement) {
        const style = getComputedStyle(node);
        const clips = style.overflowX !== 'visible' || style.overflowY !== 'visible';
        if (style.display === 'none' || style.visibility === 'hidden'
            || (clips && node !== document.documentElement && node !== document.body
                && (node.scrollWidth > node.clientWidth + 1 || node.scrollHeight > node.clientHeight + 1))) {
          hidden = true;
        }
      }
      if (hidden) clipped.push(el.dataset.copy);
    }
    return { units, clipped };
  });

  const cdp = await context.newCDPSession(page);
  await cdp.send('DOM.enable');
  await cdp.send('CSS.enable');
  const { root: doc } = await cdp.send('DOM.getDocument', { depth: -1 });
  const { nodeIds } = await cdp.send('DOM.querySelectorAll', { nodeId: doc.nodeId, selector: '[data-copy]' });
  const families = new Set();
  for (const nodeId of nodeIds) {
    const { fonts } = await cdp.send('CSS.getPlatformFontsForNode', { nodeId });
    for (const font of fonts) families.add(font.familyName);
  }

  process.stdout.write(JSON.stringify({
    viewport,
    browser_version: browser.version(),
    requests: { blocked, failed },
    units: layout.units,
    clipped: layout.clipped,
    platform_fonts: [...families].sort(),
  }));
} finally {
  await browser.close();
}
