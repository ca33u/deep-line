# Deep Line — Connect IQ Store kit

Prepared: 2026-08-28

This folder contains the copy and image assets for the first Connect IQ Store
submission. The listing deliberately describes only behavior present in the
current build.

## Submission fields

| Field | Value |
|---|---|
| App name | Deep Line |
| App type | Device app / watch app |
| Category | Games |
| Price | Free |
| Primary language | English |
| Permissions | None |
| Support URL | https://github.com/ca33u/deep-line/issues |
| Privacy URL | https://github.com/ca33u/deep-line/blob/main/PRIVACY.md |
| Source / website | https://github.com/ca33u/deep-line |
| Supported products | fēnix 7X Pro Solar Edition (no Wi-Fi), vívoactive 6 |

## Files

- `listing-en.md` — primary title, short and full descriptions.
- `listing-ru.md` — optional Russian store localization. The gameplay UI remains
  English in v0.1, and the Russian listing says so explicitly.
- `release-notes.md` — first-release notes in both languages.
- `submission-checklist.md` — final checks before pressing Submit.
- `assets/app-icon-500.png` — required 500×500 sRGB store icon.
- `assets/device-icon-mip-128.png` — optional 128×128 low-color on-device icon.
- `assets/device-icon-amoled-128.png` — optional 128×128 full-color on-device icon.
- `assets/hero-1440x720-en.png` — English hero image.
- `../art/source/store-hero-v10.png` — text-free cinematic source artwork used by
  the hero image. The diver is the exact first pose selected by the user.
- `assets/screenshots/` — real Simulator captures and store-ready crops.
- `../bin/deep-line.iq` — signed upload package, generated from the two products in
  `manifest.xml`.

## Garmin asset rules used

- Store icon: 500×500 px, sRGB, solid non-black background, 10 px or more safe
  padding, no text, no Garmin branding.
- Optional on-device icons: 128×128 px; the MIP version uses the Garmin 64-color
  palette.
- Hero: 1440×720 px. Text is localized in separate English and Russian files.

The current hero uses large original key-art poses rather than scaled runtime
sprites. The previous sprite-based covers remain as `hero-v1-*` only for visual
history and should not be uploaded.

The canonical requirements are maintained by Garmin:
https://developer.garmin.com/brand-guidelines/connect-iq/
