# Deep Line

A one-button freediving rhythm game for round Garmin watches.

This repository currently contains the first playable prototype. The diver begins beside the buoy with a short duck-dive animation, descends automatically along a fixed line, times equalization cues, completes a two-target tag-and-turn sequence at 20 m, follows kick cues on ascent and glides through a slowed final three metres before settling at the surface.

Deep Line is an arcade game. It is not a breath-hold trainer, dive computer or safety tool, and it must not be used during a real dive.

## Prototype controls

- START / ENTER or tap: start, equalize, take the tag, kick, retry
- BACK or MENU during a dive: pause
- BACK from menu or result: exit

## Visual system

The game uses short illustrated animation loops for the surface start, duck dive, descent, ascent, equalization and bottom turn, plus dedicated buoy, tag and depth-linked wildlife assets. The bottom turn follows the interaction phases instead of looping independently: reach for the tag, pivot, then settle head-up. A forage-fish school, smaller background green turtle and distant orca enter from outside the display, cross behind the line during descent and leave through the opposite edge at plausible points in the upper 20 m. Each animal has a subtle two-frame swim cycle. Compact frames are loaded on 280 px MIP watches and larger frames on 390 px AMOLED watches.

Water uses a ten-step animated gradient on AMOLED and a palette-safe stepped teal gradient on 64-color MIP. Moving rays, drifting particles, surface waves, buoy bob, tag sway, line markers, timing rings and HUD elements stay code-drawn to keep memory and redraw cost predictable.

Image-generation source sheets and their art-direction notes live in `art/`. Watch-ready assets live in `resources/drawables/generated/`.

## Building

SDK 9.2.0 and a Garmin developer key are required.

```sh
GARMIN_DEVELOPER_KEY=/path/to/developer_key.der ./scripts/build-debug.sh fenix7xpronowifi
GARMIN_DEVELOPER_KEY=/path/to/developer_key.der ./scripts/run-tests.sh
```

The prototype manifest intentionally targets only fēnix 7X Pro no-Wi-Fi and vívoactive 6. The device matrix will expand only after the core loop passes its ten-run gameplay gate.
