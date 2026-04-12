# Cartographic Data License

## countries.geo.json

**Source:** https://github.com/johan/world.geo.json (MIT License)

**Underlying data:** Natural Earth — https://www.naturalearthdata.com/

**License status:** Natural Earth data is released into the **public domain**. No permission is needed to use it. See https://www.naturalearthdata.com/about/terms-of-use/ for the official statement.

**Why it's here:** The `editorial-sketch` worker agent (`cogni-visual/agents/editorial-sketch.md`) uses this file to draw accurate country outlines for cartographic-outline sketches in editorial infographics. LLMs cannot reliably draw country shapes from descriptions, so we bundle real geographic data and ask the model only to place markers on top of the outline.

**Resolution:** 1:110M (low-resolution Natural Earth), 180 countries, ~257 KB. Adequate for editorial-scale infographic sketches where the outline is a landmark, not a reference map. If higher detail is ever needed, the same package also ships individual country files at medium resolution — swap the file, no code changes.

**Attribution for rendered output:** None required (public-domain source). We still credit Natural Earth in this LICENSE file as a courtesy to the project.
