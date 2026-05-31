# Nocturne

iOS citizen science app: measures light pollution via iPhone camera, renders a side-by-side comparison (actual sky vs. Bortle Class 1), and uploads measurements to a crowdsourced Supabase/PostGIS global heatmap.

## Stack
- Swift 6, iOS 17+ minimum deployment target
- SwiftUI (all views); UIViewRepresentable only when SwiftUI has no AVFoundation equivalent
- AVFoundation — AVCaptureSession, manual exposure (`ExposureMode.custom`); fixed measurement protocol: ISO 1600, 4s exposure, wide-angle camera
- CoreLocation — CLLocationManager; CoreMotion — CMMotionManager (device attitude for sky orientation)
- SpriteKit — star field renderer (2D, GPU-accelerated); cap at 5,000 sprites per scene, label faint stars as "density" above that
- MapKit + MKMapView with MKOverlayRenderer for heatmap (client-side gradient tiles)
- Supabase Swift SDK (`supabase-swift` 2.x) — Postgres + PostGIS + Realtime; anon key loaded from `Config.xcconfig` (excluded from git, never hardcoded)
- Open-Meteo API (free, no key required) — cloud cover validation at measurement time
- Hipparcos/Tycho-2 bundled SQLite (mag ≤ 9.0, ~300K stars, ~15MB); GRDB.swift for local measurement log

## Conventions
- Swift strict concurrency (`-strict-concurrency=complete`) — async/await throughout, no callbacks; all network calls (Open-Meteo, Supabase) off the main thread
- MVVM: Views are dumb, ViewModels own business logic, Services own I/O
- File naming: PascalCase for types/files, camelCase for variables; magic numbers go in `Constants.swift`
- Use `guard-let` or `if-let`; force-unwrap (`!`) is a build-breaking convention violation
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`

## Gotchas
- Measurement validation is mandatory — run tilt check, daylight check, and hot-pixel check before uploading; skipping any contaminates the global map
- Calibration uses a per-model lookup table (iPhone 12–16 Pro) via polynomial regression against VIIRS satellite data; unsupported models skip gracefully
- Phase scope: stay within `IMPLEMENTATION-ROADMAP.md`; do not implement features outside the current phase

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

Nocturne is an iOS citizen science app that measures light pollution from the night sky using the iPhone's camera, then renders a side-by-side comparison: the user's actual washed-out sky vs. the same sky under pristine Bortle Class 1 conditions. Every measurement uploads to a crowdsourced Supabase/PostGIS database that powers a global light pollution heatmap. App Store distribution, free, donation model deferred.

## Current State

**Phase 4: Polish & App Store Prep** (complete)
Phases 0–4 implemented. Onboarding, accessibility, share composite, App Store metadata done.
See IMPLEMENTATION-ROADMAP.md for full phase details and acceptance criteria.

## Stack

- Language: Swift 6, iOS 17+ minimum deployment target
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

## How To Run

- Swift strict concurrency (`-strict-concurrency=complete`) — async/await throughout, no callbacks
- MVVM: Views are dumb, ViewModels own business logic, Services own I/O
- File naming: PascalCase for types/files, camelCase for variables
- No force unwraps (`!`) — use guard-let or if-let everywhere
- All magic numbers extracted to named constants in `Constants.swift`
- Conventional commits: feat:, fix:, chore:, docs:

## Known Risks

- Do not use UIKit views directly — wrap in UIViewRepresentable only when SwiftUI has no equivalent
- Do not store Supabase anon key in source code — load from `Config.xcconfig` excluded from git
- Do not call Open-Meteo or Supabase on the main thread — all network calls async off main
- Do not render more than 5,000 star sprites per SpriteKit scene — cap and label faint stars as "density"
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
- Do not skip measurement validation (tilt check, daylight check, hot-pixel check) — bad data contaminates the global map

## Next Recommended Move

Use this context plus the README and supporting docs to resume the next active task, then promote the repo beyond minimum-viable by capturing a dedicated handoff, roadmap, or discovery artifact.

<!-- portfolio-context:end -->
