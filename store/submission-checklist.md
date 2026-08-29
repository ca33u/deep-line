# Connect IQ submission checklist

## Ready

- [x] App name and English listing copy
- [x] Optional Russian listing copy with English-UI disclosure
- [x] Safety disclaimer in both descriptions
- [x] Privacy policy for a no-data, offline app
- [x] Store icon specification: 500×500 sRGB
- [x] On-device icon specification: 128×128 MIP and AMOLED
- [x] Hero specification: 1440×720, localized variants
- [x] Strict builds for all 14 manifest product IDs (16 exported device variants)
- [x] Model tests: 27/27
- [x] Simulator smoke on 260, 280, 390 and 454 px round displays
- [x] No permissions in manifest
- [x] Re-export signed release-candidate `.iq` for the expanded device matrix

## Before submission

- [ ] Finish the 10-run gameplay gate on a real fēnix 7X Pro
- [ ] Confirm touch input on a real vívoactive 6 or equivalent device
- [x] Simulator smoke the added fēnix 8 and fēnix 9 screen families
- [x] Review fresh fēnix 9 Pro AMOLED title, campaign, shallow timing and deep
  Sea of Cortez gameplay screenshots
- [x] Push `PRIVACY.md` so its public GitHub URL resolves
- [x] Re-export the final `.iq` with the same developer key after hardware fixes
- [ ] Upload the `.iq`, icon, hero, screenshots and localized copy
- [ ] Preview the unpublished listing on both desktop and mobile
- [ ] Submit for Garmin review

Do not submit before the hardware gate. Garmin explicitly recommends publishing
only after the supported products are fully tested.
