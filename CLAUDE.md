# Nocturne

## Overview
Nocturne is an iOS citizen science app that measures light pollution from the night sky using the iPhone's camera, then renders a side-by-side comparison: the user's actual washed-out sky vs. the same sky under pristine Bortle Class 1 conditions. Every measurement uploads to a crowdsourced Supabase/PostGIS database that powers a global light pollution heatmap. App Store distribution, free, donation model deferred.

## Tech Stack
- Language: Swift 5.10, iOS 17+ minimum deployment target
- UI Framework: SwiftUI (all views, no UIKit except where AVFoundation forces it)
- Camera: AVFoundation — AVCaptureSession with manual exposure (ExposureMode.custom)
- Location: CoreLocation — CLLocationManager
- Motion: CoreMotion — CMMotionManager (device attitude for sky orientation)
- Rendering: SpriteKit — star field renderer (2D, GPU-accelerated, avoids Metal boilerplate)
- Maps: MapKit + MKMapView with MKOverlayRenderer for heatmap
- Backend: Supabase Swift SDK (`supabase-swift` 2.x) — Postgres + PostGIS + Realtime
- Weather: Open-Meteo API (free, no key required) — cloud cover validation
- Star Catalog: Hipparcos/Tycho-2 bundled as SQLite (filtered to mag ≤ 9.0, ~300K stars)
- Local DB: SQLite via GRDB.swift — local measurement log

## Development Conventions
- Swift strict concurrency (`-strict-concurrency=complete`) — async/await throughout, no callbacks
- MVVM: Views are dumb, ViewModels own business logic, Services own I/O
- File naming: PascalCase for types/files, camelCase for variables
- No force unwraps (`!`) — use guard-let or if-let everywhere
- All magic numbers extracted to named constants in `Constants.swift`
- Conventional commits: feat:, fix:, chore:, docs:

## Current Phase
**Phase 4: Polish & App Store Prep** (complete)
Phases 0–4 implemented. Onboarding, accessibility, share composite, App Store metadata done.
See IMPLEMENTATION-ROADMAP.md for full phase details and acceptance criteria.

## Key Decisions
| Decision | Choice | Rationale |
|----------|--------|-----------|
| Star renderer | SpriteKit (not Metal) | Sufficient for 300K point sprites; avoids Metal shader complexity on first build |
| Backend | Supabase + PostGIS | Native Swift SDK, free tier, PostGIS geospatial built-in; no custom server needed |
| Calibration approach | Per-model lookup table (iPhone 12–16 Pro) | Polynomial regression against VIIRS satellite data; skip unsupported models gracefully |
| Measurement protocol | Fixed: ISO 1600, 4s exposure, wide angle camera | Reproducible across sessions; max ISO/exposure within what AVCaptureDevice allows per model |
| Star catalog | Hipparcos/Tycho-2 bundled SQLite | Authoritative, offline-first, filtered to mag ≤ 9.0 reduces DB size to ~15MB |
| Weather validation | Open-Meteo cloud cover % at measurement time | Free, no API key, accurate enough to tag cloudy vs. clear measurements |
| Map heatmap | Client-side MKOverlayRenderer with gradient tiles | Avoids tile server complexity; sufficient for <500K measurements |

## Do NOT
- Do not use UIKit views directly — wrap in UIViewRepresentable only when SwiftUI has no equivalent
- Do not store Supabase anon key in source code — load from `Config.xcconfig` excluded from git
- Do not call Open-Meteo or Supabase on the main thread — all network calls async off main
- Do not render more than 5,000 star sprites per SpriteKit scene — cap and label faint stars as "density"
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
- Do not skip measurement validation (tilt check, daylight check, hot-pixel check) — bad data contaminates the global map
