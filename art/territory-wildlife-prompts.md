# Territory wildlife prompt set

Generated with OpenAI built-in ImageGen on 2026-08-27. The initial batch used
`art/source/orca.png` as a style reference. Manta and hammerhead were later
rebuilt from `art/source/thresher-shark.png` so the shared style did not leak
orca anatomy or markings into their silhouettes.

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
- **Visayan Sea / Philippines:** pelagic thresher shark, left-facing, extremely long upper
  tail lobe curving gently upward.
- **Red Sea:** oceanic manta ray, right-facing three-quarter side profile, both
  broad wings, two cephalic lobes and one complete thin tail.
- **Bahamas:** scalloped hammerhead shark, left-facing side profile, eyes at the
  ends of an anatomically plausible hammer-shaped head.
- **Greenland Sea:** narwhal, right-facing near-side profile, one straight spiral
  tusk, rounded forehead, compact pectoral flippers, broad tail and no dorsal fin.

The Visayan campaign preview uses the existing shallow green turtle and carries
that same turtle into the opening of the dive. The pelagic thresher remains the
territory's signature deeper encounter around the Monad cleaning-station range;
it is no longer presented as an animal already swimming through the first metres.

The first sea-lion output baked a checkerboard into RGB. It received a second
`background-extraction` edit with the instruction to change only the background
to genuine alpha while preserving the animal. All five accepted sources are
RGBA and are downscaled reproducibly by `scripts/build-art-assets.sh`.

## Anatomy correction: manta and hammerhead

The first manta looked like an orca with wings, and the first hammerhead split
the cephalofoil into cartoon eye stalks. Both were replaced rather than edited.

- **Manta v2:** near-dorsal view; one continuous diamond-shaped pectoral disc,
  two compact cephalic lobes around a terminal mouth, lateral eyes, and one long
  unbarbed whip tail. Charcoal/slate dorsal color only, with no orca patches.
- **Hammerhead v2:** slight top-down view; one continuous broadly arched
  scalloped cephalofoil, small eyes integrated at its lateral tips, a slender
  fusiform torso, tall first dorsal fin, small second dorsal fin, and a
  heterocercal tail. No protruding eye bulbs or black-and-white markings.

The accepted manta then received a background-only extraction pass because its
first output contained a baked checkerboard. Both replacement sources are RGBA
and were checked again at their actual runtime sizes (`80x54` / `112x76` for the
manta and `90x48` / `126x68` for the hammerhead).

## Second animation frames

Each accepted source was used as a high-invariance `precise-object-edit` target.
The prompt locked identity, orientation, colors, markings, proportions, fin or
limb count, and transparent canvas, then requested exactly one small motion:

- sea lion: fore flippers sweep back and the torso takes a slight S-curve;
- thresher shark: caudal peduncle and long upper tail lobe flex oppositely;
- manta: both pectoral wing tips move into a gentle downstroke;
- hammerhead: rear torso and heterocercal tail flex oppositely while the entire
  cephalofoil remains locked;
- narwhal: rear torso takes a restrained S-curve while the tail flukes lift.

All five generated edits received a background-only extraction pass. Accepted
second frames use the `-1.png` suffix and keep the same runtime dimensions as
their matching first frame.

## Arctic ice residents

`ringed-seal-floe.png` was rebuilt from the former leopard-seal composition as a
high-invariance edit: the ice, perspective and layout stayed fixed while the
animal became a compact Arctic ringed seal with a rounded head, short muzzle and
large pale rings on a lighter gray coat. The simplified pattern, separated near
flipper and split rear flippers remain legible at 72×42. A background-extraction
pass restored true alpha.

`polar-bear-floe.png` now belongs to the geographically coherent Greenland Sea
territory. The accepted sprite uses the compact floe layout, true alpha, and a
raised side-profile with a clear belly gap and separated legs so the animal
survives the final 72×42 / 100×58 downscale.

Both surface residents also have restrained second frames. The polar bear keeps
its head raised while advancing one front paw; the ringed
seal lifts its head and near front flipper. Each edit locks the canvas, ice-floe
placement, scale, palette and orientation so the habitat stays stable while only
the animal moves. The first outputs baked a checkerboard into RGB, so both
accepted `-1.png` sources received a separate background-extraction pass and
were verified to contain real alpha.

Both Arctic composite pairs are finally mirrored to face left. They still enter
from and occupy the right surface lane, but now look inward toward the buoy and
diver instead of outward into the clipped edge of the round screen.

The former Southern Ocean set mixed a requested polar bear with Antarctic Adélie
penguins and a leopard seal. It was replaced by one Arctic ecosystem: polar bear
and ringed seal on the surface, two-frame narwhal as the hero encounter, and orca
in the background. The old penguin and leopard-seal files are obsolete.
