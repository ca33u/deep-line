# Deep Line

A one-button freediving rhythm game for round Garmin watches.

This repository contains a playable campaign prototype. Fifteen dives progress
from 10 m to an intentionally aspirational 150 m finale across the Sea of Cortez,
the Visayan Sea, the Red Sea, the Atlantic Ocean and the Greenland Sea. The first
milestones echo common recreational freediving course ranges; 126 m matches the
current men's AIDA CWTB record represented by the diver's bifins, while 145 m and
150 m are explicitly fictional aspirational goals.

The diver begins beside the buoy with a short duck-dive animation, descends
automatically along a fixed line, times equalization cues, answers a single
timed tag-and-turn cue, follows kick cues on ascent and glides through a slowed
final three metres before settling at the surface. Deeper levels scale travel
speed, cue count, timing pressure and FLOW penalties without adding controls.
Completing the whole dive awards at least one star; two stars are required to
unlock the next depth, so answering every signal immediately is not enough.

Deep Line is an arcade game. It is not a breath-hold trainer, dive computer or safety tool, and it must not be used during a real dive.

## Prototype controls

- START / ENTER or tap: open campaign, dive, equalize, take the tag, kick
- UP / DOWN or left / right tap on the campaign screen: preview dives
- ENTER or bottom tap: start an unlocked dive
- BACK or MENU during a dive: pause
- On pause: UP / DOWN selects RESUME, MAIN MENU, or EXIT APP; START confirms;
  tap selects an action directly; BACK returns to the title
- BACK from campaign: title; BACK from result: campaign; BACK from title: exit

## Visual system

The game uses short illustrated animation loops for the surface start, duck dive,
descent, ascent, equalization and bottom turn, plus dedicated buoy, tag and
depth-linked wildlife assets. The bottom turn follows the interaction phases
instead of looping independently: reach for the tag, pivot, then settle head-up.
Five ocean palettes and territory silhouettes distinguish the campaign. Fish,
turtles, sea lions, thresher and hammerhead sharks, manta rays, orcas and
narwhals enter from outside the display and cross behind gameplay at
depth-relative encounter points. Compact frames are used on 280 px MIP watches
and larger frames on 390 px AMOLED watches.

The campaign animal is part of the dive scene rather than a separate thumbnail:
it keeps the same sprite frame, direction and travel phase after DIVE is pressed.
The diver likewise begins the duck dive at the exact campaign coordinates. The
surface remains fixed while the diver clears the first metres, then the camera
takes over without moving the waterline down the screen.

Water uses a twenty-step animated territory gradient on AMOLED and palette-safe
stepped variants on 64-color MIP. Drifting particles, surface waves, buoy bob,
tag sway, adaptive line markers, timing rings and HUD elements stay code-drawn
to keep memory and redraw cost predictable.

Image-generation source sheets and their art-direction notes live in `art/`. Watch-ready assets live in `resources/drawables/generated/`.

## Building

SDK 9.2.0 and a Garmin developer key are required.

```sh
GARMIN_DEVELOPER_KEY=/path/to/developer_key.der ./scripts/build-debug.sh fenix7xpronowifi
GARMIN_DEVELOPER_KEY=/path/to/developer_key.der ./scripts/run-tests.sh
```

The prototype manifest intentionally targets only fēnix 7X Pro no-Wi-Fi and vívoactive 6. The device matrix will expand only after the core loop passes its ten-run gameplay gate.
