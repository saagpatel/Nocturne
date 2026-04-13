# Nocturne — App Store Connect Metadata

## Identity

| Field | Value |
|-------|-------|
| **Name** | Nocturne |
| **Subtitle** | Measure Light Pollution |
| **Bundle ID** | com.nocturne.app |
| **SKU** | NOCTURNE-001 |
| **Primary Category** | Weather |
| **Secondary Category** | Education |
| **Age Rating** | 4+ |
| **Price** | Free |
| **Availability** | All territories |

---

## Keywords

```
light pollution,night sky,bortle scale,dark sky,astronomy,citizen science,sky brightness,star gazing,light map,sky quality
```

*(100 character limit)*

---

## Description

Nocturne turns your iPhone into a scientific instrument for measuring light pollution. Point your camera at the night sky, and Nocturne captures a calibrated exposure to calculate your sky's darkness on the Bortle scale — the international standard for sky quality.

Then see what you're missing: a real-time, side-by-side star field comparison shows your washed-out sky next to the same patch of sky under pristine Bortle Class 1 conditions — thousands of stars, the Milky Way, and deep-sky objects that light pollution hides from view.

Every measurement contributes to a crowdsourced global light pollution map, building a living picture of how artificial light affects our night skies.

KEY FEATURES

• Calibrated sky brightness measurement using your iPhone's camera (ISO 1600, 4-second exposure)
• Automatic Bortle class classification (1–9 scale)
• Side-by-side star field comparison: your sky vs. a pristine dark sky
• Interactive global light pollution heatmap powered by community data
• Measurement validation: tilt detection, daylight rejection, and hot-pixel filtering
• Weather-aware: cloud cover tagged via Open-Meteo for data quality
• Per-device calibration against VIIRS satellite reference data (iPhone 12–16 Pro)
• Complete measurement history with reverse-geocoded locations
• Offline-first: all measurements stored locally with automatic cloud sync

BUILT FOR CITIZEN SCIENCE

Nocturne is designed for accuracy, not approximation. Each measurement follows a fixed protocol — same ISO, same exposure, same wide-angle lens — so readings are reproducible and comparable across sessions, devices, and locations. The calibration pipeline maps raw pixel luminance to magnitudes per arc-second squared (mag/arcsec²), the unit used by professional sky quality meters.

---

## Promotional Text

*(Optional — appears above description, can be updated without a new app version)*

```
How dark is your sky tonight? Point your iPhone up and find out — then see the stars you're missing.
```

---

## Support URL

https://nocturne.app/support

---

## Privacy Policy URL

https://nocturne.app/privacy

---

## Screenshots

### Required Sizes
- **6.7" Display** — 1290 × 2796 px (iPhone 16 Pro Max / iPhone 15 Pro Max)
- **6.1" Display** — 1179 × 2556 px (iPhone 16 / iPhone 15)

### Screenshot Plan (4 screenshots per size)

| # | Screen | Simulator State | Headline Overlay |
|---|--------|-----------------|------------------|
| 1 | MeasurementView | Camera viewfinder active, night sky framed, Bortle Class 4 result card visible | "See how dark your sky really is." |
| 2 | ComparisonView | Side-by-side split: left washed-out sky, right Bortle 1 star field with Milky Way visible | "Discover the stars light steals from you." |
| 3 | HeatmapView | Global heatmap with gradient overlays, user pin highlighted, community data points visible | "Join a global network of sky watchers." |
| 4 | HistoryView | Measurement log with 5+ entries, Bortle classes, reverse-geocoded locations, timestamps | "Every reading. Every sky. On record." |

### How to Take Screenshots
1. Open Xcode → Simulator → select iPhone 16 Pro Max
2. Build and run the Nocturne target
3. Navigate to each screen state (use pre-seeded test data for history and heatmap views)
4. **Xcode menu: Product → Simulator → Take Screenshot** (saves to Desktop)
   OR: `xcrun simctl io booted screenshot ~/Desktop/screenshot.png`
5. Repeat for iPhone 16 (6.1") by switching simulator
6. Add marketing text overlays in Sketch, Figma, or Canva before uploading

---

## App Review Notes

```
Nocturne measures night sky brightness using the iPhone camera. Camera and location permissions
are required for the core measurement feature.

To test the core flow:
1. Grant camera and location permissions when prompted
2. Tap "Measure" and point the device at the sky (or a dark ceiling for review purposes)
3. Hold the device steady for the 4-second calibrated exposure
4. View the Bortle class result and the side-by-side star field comparison
5. Tap "Map" to see the global heatmap with community measurements

Note: Measurements taken indoors or in bright conditions will return Bortle Class 9 (most light-polluted),
which is expected behavior. The app does not crash or error on indoor use.
```

---

## Checklist Before Submission

- [ ] Bundle ID `com.nocturne.app` registered in Apple Developer portal
- [ ] App icon 1024×1024 appears correctly in Xcode asset catalog (no warnings)
- [ ] Archive succeeds: `Product → Archive` with no errors
- [ ] Validate App passes with 0 errors (check privacy manifest, entitlements)
- [ ] All 8 screenshots uploaded (4 per required size)
- [ ] Description, keywords, subtitle filled in App Store Connect
- [ ] Price set to Free in Pricing and Availability
- [ ] Age rating questionnaire complete (4+)
- [ ] Support URL and Privacy Policy URL provided
- [ ] Camera and Location usage descriptions present in Info.plist
- [ ] PrivacyInfo.xcprivacy includes camera, location, and UserDefaults declarations
- [ ] TestFlight internal test complete (full measurement flow, heatmap visible, history populated)
- [ ] Submit for Review
