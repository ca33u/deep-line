# Territory wildlife prompt set

Generated with OpenAI built-in ImageGen on 2026-08-27. The existing
`art/source/orca.png` was supplied as a style reference only.

## Shared prompt

```text
Use case: stylized-concept
Asset type: tiny side-scrolling Garmin watch game wildlife sprite source
Primary request: create exactly one anatomically plausible [SUBJECT] swimming
horizontally [DIRECTION] in a calm natural pose, with a silhouette readable at
40–90 pixels.
Input image: style reference only; match its clean premium minimalist 2D
indie-game rendering and outline weight, but replace the animal completely.
Scene/backdrop: genuinely transparent background, isolated subject only.
Style/medium: crisp hand-painted 2D game sprite, chunky anatomical silhouette,
ink-navy outline, restrained internal shading.
Composition/framing: full animal centered with generous transparent padding;
nothing cropped.
Color palette: species-appropriate charcoal or deep slate, muted light accents,
subtle aqua or icy-cyan rim light.
Constraints: correct limb/fin count, complete tail and silhouette, no text, no
scenery, no bubbles, no shadow, no watermark; true alpha transparency.
Avoid: extra limbs or fins, detached parts, aggressive pose, photorealism,
white background, glow cloud.
```

## Subjects

- **Mexico:** California sea lion, right-facing, fore flippers swept back.
- **Philippines:** pelagic thresher shark, left-facing, extremely long upper
  tail lobe curving gently upward.
- **Red Sea:** oceanic manta ray, right-facing three-quarter side profile, both
  broad wings, two cephalic lobes and one complete thin tail.
- **Bahamas:** scalloped hammerhead shark, left-facing side profile, eyes at the
  ends of an anatomically plausible hammer-shaped head.
- **Antarctica:** Adélie penguin, right-facing underwater dart pose, both
  flipper-wings swept slightly backward and feet together.

The first sea-lion output baked a checkerboard into RGB. It received a second
`background-extraction` edit with the instruction to change only the background
to genuine alpha while preserving the animal. All five accepted sources are
RGBA and are downscaled reproducibly by `scripts/build-art-assets.sh`.
