# Nocturne

[![Swift](https://img.shields.io/badge/Swift-f05138?style=flat-square&logo=swift)](#) [![License](https://img.shields.io/badge/license-MIT-blue?style=flat-square)](#)

> Point at the sky. Get a Bortle class. See what the stars should look like.

Nocturne is an iOS app that measures local light pollution using your iPhone camera. Point at the night sky, get a calibrated sky brightness reading in mag/arcsec², and see a side-by-side comparison of your actual sky versus a pristine Bortle Class 1 reference — rendered from the real Hipparcos/Tycho-2 star catalog.

## Features

- **Sky brightness measurement** — 4-second long exposure via AVFoundation, calibrated luminance conversion with per-device coefficients and Rec. 709 luma weights
- **Bortle class rating** — maps sky brightness to Bortle classes 1–9 (16.5–21.75 mag/arcsec² range)
- **4-gate validation** — rejects daylight measurements (solar altitude > −6°), tilted-phone readings (>20° from zenith), and saturated frames (>1% saturated pixels); tags cloud cover without rejecting
- **Sky comparison view** — side-by-side SpriteKit star fields: your measured sky vs. a Bortle Class 1 reference at the same coordinates, drawn from Hipparcos/Tycho-2 catalog data
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
| Backend (optional) | Supabase (Postgres + Storage) |
| Star catalog | Hipparcos/Tycho-2 (bundled subset) |

## Architecture

The measurement pipeline runs as a Swift `actor`: AVFoundation captures a manual-exposure frame, a pixel-sampling pass computes mean luminance over the center crop, and a calibration lookup converts raw luma to mag/arcsec² using device-specific coefficients stored in a bundled JSON table. The 4-gate validator runs before any pixel math and short-circuits with a typed rejection reason. The SpriteKit comparison view queries a bundled SQLite subset of the Hipparcos/Tycho-2 catalog filtered to the visible magnitude range for the measured sky brightness.

## License

MIT