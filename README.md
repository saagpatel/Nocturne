# Nocturne

[![Platform](https://img.shields.io/badge/platform-iOS%2017%2B-blue?logo=apple)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange?logo=swift)](https://swift.org)
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)
[![Xcode](https://img.shields.io/badge/Xcode-16%2B-blue?logo=xcode)](https://developer.apple.com/xcode/)

Nocturne is an iOS app that measures local light pollution using your iPhone camera. Point the phone at the sky and it returns sky brightness in mag/arcsec² and a Bortle class rating. Results are stored locally and — when Supabase is configured — uploaded to a shared heatmap so you can visualize light pollution across a map.

## Features

- **Sky brightness measurement** — captures a 4-second long exposure through AVFoundation, samples the center crop of the frame, and converts raw pixel luminance to calibrated mag/arcsec² using per-device calibration coefficients and Rec. 709 luma weights
- **Bortle class rating** — maps sky brightness to Bortle classes 1–9 using standard thresholds (16.5–21.75 mag/arcsec²)
- **4-gate validation pipeline** — rejects measurements that are taken during daylight (solar altitude > −6°), with the phone tilted more than 20° from zenith, or with a bright light source in frame (>1% saturated pixels); cloud cover is tagged but never rejects
- **Sky comparison view** — side-by-side SpriteKit star fields rendered from the Hipparcos/Tycho-2 catalog: your measured sky versus a pristine Bortle Class 1 reference at the same coordinates
- **Global heatmap** — light pollution heat tiles aggregated from community measurements, rendered as color-coded MKOverlay layers (blue = pristine, red = urban) on a hybrid satellite map
- **Measurement history** — local SQLite store via GRDB with full measurement records including location, cloud cover, and calibration status
- **Offline-first** — all measurements are saved locally first; uploads to Supabase retry automatically on reconnect, with optional cellular upload control

## Tech Stack

| Layer | Technology |
|---|---|
| Language | Swift 6, strict concurrency |
| UI | SwiftUI + SpriteKit (star renderer) + MapKit (heatmap overlay) |
| Camera | AVFoundation (manual ISO/exposure control) |
| Local database | GRDB.swift (SQLite) |
| Remote sync | Supabase Swift SDK |
| Sensors | CoreMotion (tilt validation), CoreLocation (GPS) |
| Weather | Open-Meteo REST API (cloud cover tagging) |
| Build | XcodeGen (`project.yml`) |

## Prerequisites

- Xcode 16 or later
- iOS 17.0+ device or simulator (camera capture requires a physical device)
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — `brew install xcodegen`
- Supabase project (optional — the app runs fully offline without it)

## Getting Started

```bash
# 1. Clone the repo
git clone <repo-url>
cd Nocturne

# 2. Configure credentials
cp Config.xcconfig.example Config.xcconfig
# Edit Config.xcconfig and set SUPABASE_URL and SUPABASE_ANON_KEY
# Leave the placeholder values to run in offline-only mode

# 3. Generate the Xcode project
xcodegen generate

# 4. Open and run
open Nocturne.xcodeproj
```

Select a physical device target for full functionality — the camera measurement flow requires a real device.

## Project Structure

```
Nocturne/
├── App/                    # App entry point and AppState (network monitor)
├── Models/                 # Data models: MeasurementRecord, HeatmapTile, CalibrationModel
├── Services/               # Business logic: MeasurementEngine, CalibrationService,
│                           #   ValidationGate, CameraService, LocationService,
│                           #   WeatherService, DatabaseManager, SupabaseService
├── ViewModels/             # Observable ViewModels for each screen
├── Views/                  # SwiftUI views: Measure, Map, History, Comparison
├── Renderers/              # SkyScene (SpriteKit), HeatmapOverlayRenderer (MapKit)
├── Utilities/              # Astrometry helpers (Julian date, equatorial→horizontal)
├── Constants.swift         # All magic numbers in one place
└── Resources/
    ├── calibration_table.json      # Per-device luminance calibration coefficients
    └── hipparcos_tycho2.sqlite     # Bundled star catalog for the comparison renderer
NocturneTests/              # 56 unit tests covering astrometry, calibration,
                            #   measurement engine, validation gate, and star catalog
scripts/
└── build_star_catalog.py   # One-time script to generate the bundled SQLite catalog
```

## Screenshot

> _Screenshot placeholder — add device screenshots here_

## License

MIT — see [LICENSE](LICENSE).
