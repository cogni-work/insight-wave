# Cogni Work (font-shipping render fixture)

The render fixture theme with one change: its copy font leads with Outfit, a licensed face this
theme ships under `assets/fonts/` and declares in `assets/fonts/faces.json`. Its slug matches the
design-system name the composition fixtures pin, and its other tokens are copies of the render
fixture theme's, so an html render of it differs only in the embedded face and the metric the
layout measures with.

Outfit Regular is the unmodified upstream static TrueType file, licensed under the SIL Open Font
License 1.1; `assets/fonts/OFL.txt` carries its copyright line and the full licence, and the
repository's root `NOTICE` lists it. It is the only copy of the file in the tree: a case that needs
a variant copies this theme into a scratch directory rather than committing a second binary.
