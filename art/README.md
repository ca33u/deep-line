# Deep Line art sources

The two source sheets in this directory were generated for Deep Line with OpenAI's built-in image generation on 2026-08-27.

- `freediver-sprite-sheet.png`: one consistent freediver in descent, ascent, equalization and bottom-turn poses.
- `dive-props-sheet.png`: a surface buoy and an underwater tag plate.
- `freediver-*-animation-sheet.png`: loopable frame strips for descent, ascent, equalization and the bottom turn.

The production PNGs under `resources/drawables/generated/` are cropped and downscaled from these sheets. They have separate compact MIP and larger AMOLED variants so the game does not scale large bitmaps at runtime.

The `DEEP LINE` menu wordmark is generated locally by
`scripts/build-title-assets.swift` with DIN Condensed Bold. It uses cream for
`DEEP`, rope-gold for `LINE`, and a subtle navy edge/shadow for legibility over
the animated ocean. The exact typography is reproducible and does not depend on
Garmin's limited runtime font set.

Runtime animation uses three descent frames, three ascent frames, two equalization frames and three turn frames. `scripts/build-art-assets.sh` rebuilds both density sets from the source strips. Only the density for the current display is loaded into memory.

## Art direction

Premium minimalist 2D indie-game art with chunky silhouettes, crisp ink-navy outlines and a restrained palette of navy, charcoal, muted aqua, warm cream and coral-orange. Assets must remain readable at roughly 20–90 pixels, use real alpha transparency and contain no text or scenery.

Generated sheets may contain a soft edge glow around their alpha silhouettes. The runtime assets intentionally preserve a small amount of it because it improves separation from the dark ocean background on both target displays.
