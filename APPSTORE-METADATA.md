# Nocturne App Store Connect Metadata

## Identity

| Field | Value |
|-------|-------|
| **Name** | Nocturne: Night Sky Meter |
| **Subtitle** | How Dark Is Your Sky? |
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
light pollution,night sky,bortle,dark sky,astronomy,stargazing,stars,sqm,skyglow
```

*(100 character limit; counts for all limited fields are below.)*

---

## Description

How dark is the sky above you? Nocturne uses your iPhone camera to estimate sky brightness and map the result to the Bortle scale.

After a reading, Nocturne draws the sky overhead at that place and time twice, from a bundled Gaia DR3 catalog of about 21,000 stars: once at your estimated brightness, once under a Bortle Class 1 sky. The second view is what you're missing. Both are rendered illustrations, not camera images.

KEY FEATURES

• Sky brightness in mag/arcsec²
• Bortle class on a scale from 1 to 9
• Side-by-side star fields based on your reading and a dark-sky reference
• Rejects readings taken in daylight, at a tilt, or with too many saturated pixels
• Cloud-cover information from Open-Meteo when weather data is available
• Brightness calculations for supported iPhone models
• A history of your saved readings, with date, brightness, and place

WHAT TO EXPECT

Nocturne is an experimental tool, not a calibrated professional meter; results vary by device and conditions. Camera frames are processed on your device and are not saved or uploaded. Weather lookup uses your coordinates and requires an internet connection. Contributing readings to a community dataset is optional and off by default.

---

## Promotional Text

*(Optional promotional field)*

```
Point your iPhone at the night sky for a Bortle-scale estimate, then see the sky overhead drawn two ways: at your brightness, and under a Bortle 1 dark sky.
```

### Field Counts

Python `len` counts the field values, including spaces and description line breaks, without Markdown fences or section headings.

| Field | Characters | Limit |
|-------|------------|-------|
| Name | 25 | 30 |
| Subtitle | 21 | 30 |
| Promotional text | 156 | 170 |
| Keywords | 80 | 100 |
| Description | 1215 | 4000 |

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

| n | Screen | Actual UI State | Device / Size | Capture | Headline Overlay |
|---|--------|-----------------|---------------|---------|------------------|
| 1 | Measure | Result from a successful physical-device reading: brightness, Bortle badge, Estimate and See Your Sky. Keep the actual values. | 6.9-inch iPhone, 1320 × 2868 px | OPERATOR: capture on device | "Estimate your sky's brightness." |
| 2 | Sky Comparison | Open See Your Sky from that same physical-device result. Show Your Sky and What You're Missing with their actual rendered star counts. No required Milky Way or object overlay. | 6.9-inch iPhone, 1320 × 2868 px | OPERATOR: capture on device | "Compare two generated skies." |
| 3 | History | Deterministic No Measurements Yet state from an isolated, empty in-memory database. The production History view is used; no synthetic readings are presented as saved physical measurements. | iPhone 18 Pro Max (6.9-inch), 1320 × 2868 px | Simulator: -AppStoreScreenshot 3 | "Browse saved readings." |
| 4 | Settings | Contribute measurements off and Allow cellular uploads disabled. Screenshot-only local bindings reset to false on every launch. | iPhone 18 Pro Max (6.9-inch), 1320 × 2868 px | Simulator: -AppStoreScreenshot 4 | "Choose whether to contribute." |

### How to Take Screenshots
1. Run `bash scripts/capture-screenshots.sh` from the repository on a Mac with Xcode, XcodeGen (if the project has not been generated), and an available **iPhone 18 Pro Max** simulator. The script generates the project if missing, builds Debug once, captures shots **3** and **4** as `screenshots/appstore/iphone-18-pro-max/03.png` and `04.png`, and verifies 1320 × 2868 dimensions. These generated files are gitignored.
2. Debug-only `-AppStoreScreenshot <n>` bypasses onboarding without changing saved preferences or the user database. Shots 3 and 4 require no permissions, live services, random values or current dates. Release does not include this mode. The default settling delay is 4 seconds; use `SHOT_WAIT_SECONDS` or per-shot `SHOT_3_WAIT_SECONDS` / `SHOT_4_WAIT_SECONDS` to override it. `DERIVED` overrides the default `.build/shots` build directory.
3. **OPERATOR: capture on device** for shots **1** and **2**. Use a physical iPhone producing 1320 × 2868 screenshots and follow the review steps below at night. Capture the successful result, then tap See Your Sky for its comparison. Keep the actual reading, star counts and rendered content. The app has no mock camera path; the script skips both shots to preserve the plan's same-physical-result requirement. Launch arguments 1 and 2 show an operator instruction, which must not be uploaded.
4. Do not stage a populated community map or individual community pins. They are not part of this screenshot plan. The scripted History screenshot deliberately uses the plan's permitted empty state.
5. Add only the planned headline overlays after capture; the script outputs the real app UI without overlays. Check the final exported dimensions before uploading. The existing 1290 × 2796 images do not satisfy this plan.

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
   The message is "The community map is not available in this version."
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
When configured, the Map tab requests heatmap data from the community backend's
"heatmap_tiles" function using the visible map bounds, whether or not contribution
is on. Cached data may be used instead of a new request.
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
