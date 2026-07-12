# Nocturne

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> Point at the sky. Get a Bortle class. See what the stars should look like.

Nocturne is an iOS app that estimates local light pollution using your iPhone camera. Point at the night sky, get an experimental sky-brightness reading in mag/arcsec², and see a side-by-side comparison of your actual sky versus a pristine Bortle Class 1 reference — rendered from a bundled Gaia DR3 display catalog.
Nocturne is currently an experimental estimator, not a calibrated professional meter. Device profiles remain provisional until validated against traceable physical references.

## Features

- **Sky brightness estimate** — long exposure via AVFoundation, provisional per-device luminance conversion, and Rec. 709 luma weights
- **Bortle class rating** — maps sky brightness to Bortle classes 1–9 (16.5–21.75 mag/arcsec² range)
- **4-gate validation** — rejects daylight measurements (solar altitude > −6°), tilted-phone readings (>20° from zenith), and saturated frames (>1% saturated pixels); tags cloud cover without rejecting
- **Sky comparison view** — side-by-side SpriteKit star fields: your measured sky vs. a Bortle Class 1 reference at the same coordinates, drawn from Gaia DR3 data
- **Global heatmap** — community measurement heat tiles rendered as color-coded `MKOverlay` layers (blue = pristine, red = urban)
- **Offline-first** — measurements saved to local GRDB SQLite first; Supabase uploads retry automatically on reconnect

## Quick Start

### Prerequisites
- Xcode 16+
- iOS 17.0+ device (camera long-exposure required)
- Supabase project (optional; local-only mode works without it)

### Installation
```bash
git clone https://github.com/saagpatel/Nocturne
open Nocturne.xcodeproj
```

### Usage
Deploy to a device. Go outside after astronomical twilight (when the sun is more than 18° below the horizon). Point the phone straight up and tap **Measure**. The 4-gate validator will guide you if conditions aren't met.

## Tech Stack

| Layer | Technology |
|-------|------------|
| Language | Swift 6, strict concurrency |
| UI | SwiftUI + SpriteKit (star renderer) + MapKit |
| Camera | AVFoundation (manual ISO/exposure) |
| Local database | GRDB.swift (SQLite) |
| Backend (optional) | Supabase (Postgres + PostGIS) |
| Star catalog | Gaia DR3 G ≤ 7 display subset (bundled, 21,329 stars) |

## Architecture

The AVFoundation camera layer runs as a Swift `actor` (`CameraService`); pixel processing and calibration run as static functions in a `MeasurementEngine` namespace. A manual-exposure frame is captured, a pixel-sampling pass computes mean luminance over the center crop, and a calibration lookup converts raw luma to mag/arcsec² using device-specific coefficients stored in a bundled JSON table. The 4-gate validator runs before any pixel math and short-circuits with a typed rejection reason. The SpriteKit comparison view queries a bundled SQLite subset of Gaia DR3 filtered to the visible magnitude range for the measured sky brightness.

The star display data are open and free to use with credit to **ESA/Gaia/DPAC**. The exact archive query and credit are embedded in the database's `provenance` table and reproduced by `scripts/build_star_catalog.py`.

## License

MIT
