# Deep Line art sources

The two source sheets in this directory were generated for Deep Line with OpenAI's built-in image generation on 2026-08-27.

- `freediver-sprite-sheet.png`: one consistent freediver in descent, ascent, equalization and bottom-turn poses.
- `dive-props-sheet.png`: a surface buoy and an underwater tag plate.

The production PNGs under `resources/drawables/generated/` are cropped and downscaled from these sheets. They have separate compact MIP and larger AMOLED variants so the game does not scale large bitmaps at runtime.

## Art direction

Premium minimalist 2D indie-game art with chunky silhouettes, crisp ink-navy outlines and a restrained palette of navy, charcoal, muted aqua, warm cream and coral-orange. Assets must remain readable at roughly 20–90 pixels, use real alpha transparency and contain no text or scenery.

Generated sheets may contain a soft edge glow around their alpha silhouettes. The runtime assets intentionally preserve a small amount of it because it improves separation from the dark ocean background on both target displays.
