# Nocturne

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#tech-stack) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](LICENSE)

> Point at the sky. Get a Bortle class. See what the stars should look like.

Nocturne is an iOS app that estimates local light pollution using your iPhone camera. It gives an experimental sky-brightness reading in mag/arcsec² and uses a bundled Gaia DR3 display catalog to render two star fields, one for your measured brightness and one for a pristine Bortle Class 1 sky.
Nocturne is currently an experimental estimator, not a calibrated professional meter. Device profiles remain provisional until validated against traceable physical references.

## Features

- **Sky brightness estimate** — long exposure via AVFoundation when supported, provisional per-device luminance conversion, and Rec. 709 luma weights
- **Bortle class rating** — maps sky brightness to Bortle classes 1–9 (class 1 at ≥21.75 mag/arcsec²; class 9 below 16.5)
- **4-gate validation** — rejects measurements when the sun is at or above −6°, the phone is tilted ≥20° from screen-up, or ≥1% of pixels are saturated. Cloud cover is recorded when available.
- **Sky comparison view** — side-by-side SpriteKit star fields: your measured sky vs. a Bortle Class 1 reference at the same coordinates, drawn from Gaia DR3 data
- **Global heatmap** (disabled in v1.0 by `FeatureFlags.communityEnabled`) — community measurement heat tiles rendered as color-coded `MKOverlay` layers (blue = pristine, red = urban)
- **Offline-first** — measurements are saved locally in SQLite via GRDB. Community uploads are disabled in v1.0.

## Quick Start

### Prerequisites
- macOS with full Xcode, the Swift 6 compiler, and active Xcode developer tools. The unit tests also need an installed iOS simulator.
- XcodeGen (required to generate the project)
- iPhone running iOS 17.0+ for camera measurements

The app bundle identifier is `com.nocturnn.app` and the configured build number is 4.

### Installation
```bash
git clone https://github.com/saagpatel/Nocturne
cd Nocturne
make generate
open Nocturne.xcodeproj
```

`make generate` creates `Config.xcconfig` from `Config.xcconfig.example` if needed. Both build configurations use `Config.base.xcconfig`, which provides placeholders and optionally includes the gitignored local config. Leave the placeholders in place for v1.0.

### Usage
For a device run, select your signing team in Xcode and use a bundle identifier your team can sign. Run the app on your iPhone and go outside when the sun is more than 6° below the horizon. Tap **Prepare Camera**, allow camera and location access, aim the rear camera at the sky, and tap **Measure Sky**. The tilt check requires the screen to be less than 20° from level and facing up. If motion data is available and you keep the rear camera aimed at the sky through validation, the reading will fail this check.

On the result screen for a successful reading, tap **See Your Sky** for the comparison.

## Verification

Run from the repository root. `make generate` preserves an existing `Config.xcconfig`, otherwise copies the
placeholder example, checks the bundled Gaia catalog, and runs XcodeGen. Keep
placeholder/local-only configuration for verification; live Supabase credentials
are unnecessary. Swift package resolution may download the declared packages.

```bash
# Simulator unit suite; signing is disabled by the Makefile
make test

# Compile the Release configuration without signing or uploading an archive
make release
```

The Makefile's simulator destination must exist locally. Override `SIMULATOR` if
needed, for example `make test SIMULATOR='platform=iOS Simulator,name=iPhone 17'`
for an installed simulator with that name. For a focused pure-data check, open the
generated project in Xcode and run `MeasurementEngineTests` in the Test navigator.
The broader simulator suite and Release build remain the checks before delivery.
There is no configured standalone lint or formatter command.

The focused measurement suite uses synthetic calibration/luminance values.
Camera capture and physical calibration require a device and separate physical
reference evidence; do not trigger uploads or live weather/backend requests merely
to verify documentation. For UI changes, inspect the affected simulator flow
with disposable data; measurement hardware behavior remains a separate device check.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6, strict concurrency |
| UI | SwiftUI + SpriteKit (star renderer) + MapKit |
| Camera | AVFoundation (manual ISO/exposure when supported) |
| Location and tilt | Core Location + Core Motion |
| Cloud cover | Open-Meteo |
| Local database | GRDB.swift (SQLite) |
| Community backend (disabled in v1.0) | Supabase (Postgres + PostGIS) |
| Star catalog | Gaia DR3 G ≤ 7 display subset (bundled, 21,329 stars) |

## Architecture

The AVFoundation camera layer runs as a Swift `actor` (`CameraService`). It requests manual exposure when supported and uses locked exposure as a fallback when available. Static functions in `MeasurementEngine` estimate luminance from the center crop and convert it to mag/arcsec² using per-model coefficients from a bundled JSON table, with defaults for unknown models. The 4-gate validator runs after pixel sampling and weather lookup, before calibration, and short-circuits with a typed rejection reason. The SpriteKit comparison view queries a bundled SQLite subset of Gaia DR3 up to the pristine sky limiting magnitude; the user scene filters that shared star list to the measured sky brightness.

The star display data are open and free to use with credit to **ESA/Gaia/DPAC**. The exact archive query and credit are embedded in the database's `provenance` table and reproduced by `scripts/build_star_catalog.py`.

## License

MIT
