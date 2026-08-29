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
| Supported products | fēnix 7X Pro Solar Edition (no Wi-Fi); fēnix 8, 8 Pro and 8 Solar families; fēnix 9, 9 Pro and 9 Pro Solar families; vívoactive 6 |

## Files

- `listing-en.md` — primary title, short and full descriptions.
- `listing-ru.md` — optional Russian store localization. The gameplay UI remains
  English in v0.1, and the Russian listing says so explicitly.
- `release-notes.md` — first-release notes in both languages.
- `submission-checklist.md` — final checks before pressing Submit.
- `assets/app-icon-500.jpg` — required 500×500 sRGB Store cover image, kept
  below the 300 KB upload limit.
- `assets/device-icon-mip-128.png` — upload to **Device 64 Color**.
- `assets/device-icon-amoled-128.png` — upload to **Device 24 bit Color**.
- Runtime launcher icons are generated from the same approved portrait at native
  40, 54, 60 and 65 px sizes through the base and round-resolution resource
  folders, so current MIP and AMOLED devices do not upscale the old 40 px icon.
- `assets/hero-1440x720-en.png` — English hero image.
- `../art/source/store-hero-v10.png` — text-free cinematic source artwork used by
  the hero image. The diver is the exact first pose selected by the user.
- `assets/screenshots/TO-UPLOAD/` — the five current sRGB Store screenshots;
  every file is below the 150 KB upload limit.
- `../art/source/store-screenshots/` — full Simulator captures, lossless PNG
  masters and optional screenshots kept away from the upload folder.
- `../bin/deep-line.iq` — signed upload package generated from every product in
  `manifest.xml`.

## Garmin asset rules used

- Store cover image: 500×500 px, sRGB, solid non-black background, below 300 KB,
  no text and no Garmin branding.
- Optional on-device icons: 128×128 px; the MIP version uses the Garmin 64-color
  palette.
- Hero: 1440×720 px. Text is localized in separate English and Russian files.

The current hero uses large original key-art poses rather than scaled runtime
sprites.

The canonical requirements are maintained by Garmin:
https://developer.garmin.com/brand-guidelines/connect-iq/
