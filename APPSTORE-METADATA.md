# Nocturne App Store Connect Metadata

## Identity

| Field | Value |
|-------|-------|
| **Name** | Nocturne: Night Sky Meter |
| **Subtitle** | Estimate Sky Brightness |
| **Bundle ID** | com.nocturnn.app |

### Proposed Listing Settings

These are submission choices for the operator to confirm in App Store Connect.

| Field | Value |
|-------|-------|
| **SKU** | NOCTURNE-001 |
| **Primary Category** | Weather |
| **Secondary Category** | Education |
| **Age Rating** | 4+ |
| **Price** | Free |
| **Availability** | All territories |

---

## Keywords

```
light pollution,night sky,bortle,dark sky,astronomy,sky brightness,stars
```

*(100 character limit; counts for all limited fields are below.)*

---

## Description

How dark is the sky above you? Nocturne uses your iPhone camera to estimate sky brightness and map the result to the Bortle scale.

After a reading, compare two generated star fields. One uses your brightness estimate. The other uses a Bortle Class 1 reference. Both use a bundled Gaia DR3 star catalog and the sky overhead at the reading's location and time.

These are illustrations based on the reading, rather than live views through the camera.

KEY FEATURES

• Experimental sky-brightness estimate in mag/arcsec²
• Bortle class estimate on a scale from 1 to 9
• Side-by-side star fields based on your reading and a dark-sky reference
• Checks for daylight, phone tilt and excessive saturated pixels
• Cloud-cover tags from Open-Meteo when weather data is available
• Provisional device profiles for supported iPhone models
• Browse saved readings with dates, brightness and location names or coordinates

KNOW WHAT YOU'RE MEASURING

Nocturne is an experimental tool, not a calibrated professional meter. Results vary by device and conditions. Camera frames are processed on your device and are not saved or uploaded. Weather lookup uses your coordinates and requires an internet connection.

---

## Promotional Text

*(Optional promotional field)*

```
How dark is your sky tonight? Get an experimental brightness estimate and compare two generated star fields.
```

### Field Counts

Python `len` counts the field values, including spaces and description line breaks, without Markdown fences or section headings.

| Field | Characters | Limit |
|-------|------------|-------|
| Name | 25 | 30 |
| Subtitle | 23 | 30 |
| Promotional text | 108 | 170 |
| Keywords | 72 | 100 |
| Description | 1196 | 4000 |

---

## Support URL

https://github.com/saagpatel/Nocturne/issues

---

## Privacy Policy URL

https://github.com/saagpatel/Nocturne/blob/main/PRIVACY.md

---

## Screenshots

### Required Sizes
- **6.9-inch iPhone:** 1320 × 2868 px.
- The current `TARGETED_DEVICE_FAMILY: "1"` targets iPhone only. If family `2` is added, also supply **13-inch iPad:** 2064 × 2752 px.

### Screenshot Plan (4 screenshots for the current iPhone target)

| # | Screen | Actual UI State | Headline Overlay |
|---|--------|-----------------|------------------|
| 1 | Measure | Result from a successful physical-device reading: brightness, Bortle badge, Estimate and See Your Sky. Keep the actual values. | "Estimate your sky's brightness." |
| 2 | Sky Comparison | Open See Your Sky from that result. Show Your Sky and What You're Missing with their actual rendered star counts. No required Milky Way or object overlay. | "Compare two generated skies." |
| 3 | History | Actual saved readings with timestamps and location names or coordinates. No minimum entry count. If none were saved, show No Measurements Yet. If the database cannot open, show History Unavailable. | "Browse saved readings." |
| 4 | Settings | Contribute measurements off and Allow cellular uploads disabled. | "Choose whether to contribute." |

### How to Take Screenshots
1. Use a physical iPhone that produces a 1320 × 2868 screenshot for the measurement and comparison captures. Follow the review steps below at night.
2. Capture the result and tap See Your Sky for the comparison. Do not change readings, star counts or rendered content for marketing.
3. Open History and Settings for the remaining captures. A simulator can show Settings and the actual empty or unavailable History state. It cannot provide a camera measurement, and this build has no seed-data route.
4. Do not stage a populated community map or individual community pins. They are not part of this screenshot plan.
5. Add only the planned headline overlays. Check the exported dimensions before uploading. The existing 1290 × 2796 images do not satisfy this plan.

---

## App Review Notes

```
Nocturne estimates sky brightness. It requires no account. A measurement needs a
physical iPhone with a back camera, camera permission and a location fix.

Navigation without a measurement:
1. On first launch, tap "Skip", or tap "Continue" twice and "Get Started".
2. Open "Settings". "Contribute measurements" is off by default.
   "Allow cellular uploads" is disabled until contribution is enabled.
3. Open "History". With an open database and no saved readings it shows
   "No Measurements Yet". If the database cannot open it shows "History Unavailable".
4. Open "Map". With no backend configured it shows "Map Unavailable".
   A configured backend needs networking and data for the viewed region to show
   colored heatmap circles. "Points" does not show individual community pins.
   No populated community map is promised in this build.

Measurement on a physical iPhone:
1. Open the "Measure" tab and tap "Prepare Camera". Allow camera and location
   access when prompted. After setup, the preview offers "Measure Sky".
2. Go outdoors at night, away from bright lights. Point toward the sky as the
   screen instructs, hold still and tap "Measure Sky". Exposure depends on hardware.
3. The solar-altitude check uses your location and the current time. It rejects
   readings unless the sun is below -6 degrees. Phone tilt of 20 degrees or more
   from zenith, or 1% or more saturated pixels, also causes "Measurement Rejected".
   A dark ceiling does not bypass these checks or guarantee a Bortle class.
4. A successful reading shows mag/arcsec², a Bortle badge and "Estimate".
   Cloud cover is shown when available; otherwise the weather field is "N/A".
   Tap "See Your Sky" to open "Sky Comparison" with "Your Sky" and
   "What You're Missing". These generated fields use the reading's location and
   time. Star counts and optional overlays vary; this is not a live camera match.
5. "History" lists readings that were saved successfully. Location names can
   fall back to coordinates. A result does not guarantee a saved history entry.

Daytime or indoor review may produce rejection or a camera/location error rather
than a result. On a simulator without a suitable back camera, "Prepare Camera"
shows "Something went wrong" and "No suitable camera found on this device."
There is no simulated measurement or preloaded-history mode. Use the navigation
steps above for simulator review and a physical device at night for the core flow.

Community uploads require configured services, a saved reading, contribution
enabled in "Settings" and an allowed connection. Turning contribution on does not
upload immediately; pending uploads are retried when the app returns to foreground.
Weather lookup sends coordinates to Open-Meteo even with contribution off.
History location names and the map use Apple online services.
```

---

## Checklist Before Submission

- [ ] Bundle ID `com.nocturnn.app` registered in Apple Developer portal
- [ ] App icon 1024×1024 appears correctly in Xcode asset catalog (no warnings)
- [ ] Archive succeeds: `Product → Archive` with no errors
- [ ] Validate App passes with 0 errors (check privacy manifest, entitlements)
- [ ] Four truthful screenshots uploaded at 1320 × 2868 for the 6.9-inch iPhone; existing 1290 × 2796 images replaced
- [ ] If family `2` is added, 13-inch iPad screenshots also supplied at 2064 × 2752
- [ ] Measurement and comparison screenshots use a real device result; history shows its actual saved, empty or unavailable state
- [ ] Description, keywords, subtitle filled in App Store Connect
- [ ] Price set to Free in Pricing and Availability
- [ ] Age rating questionnaire complete (4+)
- [ ] Support URL and Privacy Policy URL provided
- [ ] Camera and Location usage descriptions present in Info.plist
- [ ] PrivacyInfo.xcprivacy declares collected Precise Location and Other Data Types for App Functionality, without identity linkage or tracking, and required-reason UserDefaults access (`CA92.1`)
- [ ] Camera frames are not declared as collected photos; camera permission purpose is in Info.plist
- [ ] TestFlight internal test records actual outcomes for permission flows, a physical-device night reading, comparison, history persistence and unavailable/error states
- [ ] Review build's backend configuration, map availability and opt-in upload behavior confirmed; review notes match those outcomes
- [ ] Submit for Review

## Copyright
© 2026 saagpatel
