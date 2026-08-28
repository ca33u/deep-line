# Deep Line art sources

The raster source art in this directory was generated for Deep Line with
OpenAI's built-in image generation on 2026-08-27.

- `freediver-*-animation-sheet.png`: the current loopable diver strips.
- `freediver-duck-dive-middle.png` and `freediver-turn-middle.png`: corrected
  standalone transition frames used instead of the rejected sheet poses.
- `dive-props-sheet.png`: the editable master for the buoy and tag plate.
- `fish-school*.png`, `green-turtle*.png`, and `orca*.png`: paired depth-life
  frames. The second orca frame carries the raised-tail phase of its tail beat.
- `sea-lion*.png`, `thresher-shark*.png`, `manta-ray*.png`,
  `hammerhead-shark*.png`, and `narwhal*.png`: paired territory-specific
  wildlife frames for Mexico, the Philippines, the Red Sea, the Bahamas, and
  Greenland. Each pair adds a restrained species-specific stroke on top of
  whole-body drift and subtle bobbing.
- `polar-bear-floe*.png` and `ringed-seal-floe*.png`: paired Arctic surface
  residents on pack ice. The bear keeps a raised, readable side-profile and
  takes a small step with separated legs; the
  seal uses enlarged ring markings and lifts its distinct head and near flipper.
  The seal appears at 145 m and the bear
  is reserved for the 150 m finale; both enter from the right while facing left,
  into the composition, and remain on the floes already included in their PNGs
  when a dive begins. No second code-drawn
  floe is placed underneath them.

The obsolete all-in-one `freediver-sprite-sheet.png` was removed after the
separate animation strips fully replaced it.

The reproducible prompt spec for territory wildlife is documented in
`territory-wildlife-prompts.md`.

The production PNGs under `resources/drawables/generated/` are cropped and downscaled from these sheets. They have separate compact MIP and larger AMOLED variants so the game does not scale large bitmaps at runtime.

The five `ocean_gradient_*_mip.png` backgrounds are generated locally by
`scripts/build-mip-backgrounds.swift`. They use only Garmin's predictable
`0x00/0x55/0xAA/0xFF` channel values plus an 8×8 ordered dither, producing a
smooth perceived depth gradient without the broad color bands seen when the
runtime quantizes arbitrary RGB values.

The `DEEP LINE` menu wordmark is generated locally by
`scripts/build-title-assets.swift` with DIN Condensed Bold. It uses pure white
for both words plus a subtle neutral shadow for legibility over the animated
ocean. Subpixel font smoothing is disabled so MIP quantization cannot create
colored fringes. The larger transparent canvas keeps the edge and shadow clear of
the bitmap bounds. The exact typography is reproducible and does not depend on
Garmin's limited runtime font set.

Runtime animation uses three descent frames, three ascent frames, two equalization frames and three turn frames. `scripts/build-art-assets.sh` rebuilds both density sets from the source strips. Only the density for the current display is loaded into memory.

## Art direction

Premium minimalist 2D indie-game art with chunky silhouettes, crisp ink-navy outlines and a restrained palette of navy, charcoal, muted aqua, warm cream and coral-orange. Assets must remain readable at roughly 20–90 pixels, use real alpha transparency and contain no text or scenery.

Generated sheets may contain a soft edge glow around their alpha silhouettes. The runtime assets intentionally preserve a small amount of it because it improves separation from the dark ocean background on both target displays.
