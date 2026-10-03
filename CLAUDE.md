# Nocturne

iOS citizen science app: measures light pollution via iPhone camera, renders a side-by-side comparison (actual sky vs. Bortle Class 1), and optionally uploads measurements to a crowdsourced Supabase/PostGIS global heatmap with user consent.

## Stack
- Swift 6, iOS 17+ minimum deployment target
- SwiftUI views; UIKit wrappers for camera preview, custom MapKit overlays, and the share sheet; UIKit image rendering for star textures and share composites
- AVFoundation — AVCaptureSession, manual exposure (`ExposureMode.custom`); target protocol: ISO 1600 and up to 4s exposure, clamped to camera limits; locked-exposure fallback when custom exposure is unavailable; wide-angle back camera
- CoreLocation — CLLocationManager; CoreMotion — CMMotionManager (gravity for tilt validation); comparison orientation uses zenith at the measurement location and time
- SpriteKit — star field renderer (2D, GPU-accelerated); catalog queries cap at 5,000 stars per scene; no overflow density label
- MapKit + MKMapView with MKOverlayRenderer for heatmap (client-side colored circles)
- Supabase Swift SDK (`supabase-swift` 2.x) — Postgres + PostGIS via inserts and RPC; no Realtime subscription; anon key loaded from `Config.xcconfig` (excluded from git, never hardcoded)
- Open-Meteo API (free, no key required) — cloud cover validation at measurement time
- Gaia DR3 bundled SQLite (G ≤ 7.0, 21,329 stars, ~1.5MB); GRDB.swift for local measurement log

## Conventions
- Swift strict concurrency (`-strict-concurrency=complete`) — async/await service APIs with framework delegate/callback bridges; all network calls (Open-Meteo, Supabase) off the main thread
- MVVM: Views are dumb, ViewModels own business logic, Services own I/O
- File naming: PascalCase for types/files, camelCase for variables; magic numbers go in `Constants.swift`
- Use `guard-let` or `if-let`; force-unwrap (`!`) violates this convention, but no build check enforces it
- Conventional commits: `feat:`, `fix:`, `chore:`, `docs:`

## Gotchas
- Measurement validation is mandatory — run tilt check, daylight check, and hot-pixel check before uploading; skipping any contaminates the global map
- Calibration uses provisional per-model coefficients (iPhone 12–16 Pro Max) in a logarithmic luminance formula; unsupported models use fallback coefficients, and all new readings are marked uncalibrated
- Phase scope: stay within `IMPLEMENTATION-ROADMAP.md`; do not implement features outside the current phase

<!-- portfolio-context:start -->
# Portfolio Context

## What This Project Is

Nocturne is an iOS citizen science app that measures light pollution from the night sky using the iPhone's camera, then renders a side-by-side comparison: the user's actual washed-out sky vs. the same sky under pristine Bortle Class 1 conditions. Measurements queue locally; uploads to the crowdsourced Supabase/PostGIS database require configuration, user consent, and foreground connectivity on Wi-Fi (or cellular uploads enabled). App Store distribution, free, donation model deferred.

## Current State

**Phase 4: Polish & App Store Prep** (implementation present; acceptance checklists remain unchecked)
Onboarding, accessibility labels, share composite, and App Store metadata are present; the map raw-points layer remains a stub and tile selection is not wired up.
See IMPLEMENTATION-ROADMAP.md for full phase details and acceptance criteria.

## Stack

- Language: Swift 6, iOS 17+ minimum deployment target
- UI Framework: SwiftUI with UIKit wrappers for camera preview, custom MapKit overlays, and the share sheet; UIKit image rendering for star textures and share composites
- Camera: AVFoundation — AVCaptureSession with manual exposure (ExposureMode.custom)
- Location: CoreLocation — CLLocationManager
- Motion: CoreMotion — CMMotionManager (gravity for tilt validation); comparison orientation uses zenith at the measurement location and time
- Rendering: SpriteKit — star field renderer (2D, GPU-accelerated, avoids Metal boilerplate)
- Maps: MapKit + MKMapView with MKOverlayRenderer for heatmap
- Backend: Supabase Swift SDK (`supabase-swift` 2.x) — Postgres + PostGIS via inserts and RPC; no Realtime subscription
- Weather: Open-Meteo API (free, no key required) — cloud cover validation
- Star Catalog: Gaia DR3 bundled as SQLite (filtered to G ≤ 7.0, 21,329 stars)
- Local DB: SQLite via GRDB.swift — local measurement log

## Conventions

- Swift strict concurrency (`-strict-concurrency=complete`) — async/await service APIs with framework delegate/callback bridges
- MVVM: Views are dumb, ViewModels own business logic, Services own I/O
- File naming: PascalCase for types/files, camelCase for variables
- No force unwraps (`!`) — use guard-let or if-let everywhere
- All magic numbers extracted to named constants in `Constants.swift`
- Conventional commits: feat:, fix:, chore:, docs:

## Known Risks

- Do not use UIKit views directly — wrap in UIViewRepresentable or UIViewControllerRepresentable when SwiftUI has no equivalent
- Do not store Supabase anon key in source code — load from `Config.xcconfig` excluded from git
- Do not call Open-Meteo or Supabase on the main thread — all network calls async off main
- Do not render more than 5,000 star sprites per SpriteKit scene — catalog queries enforce the cap; no density label is implemented
- Do not add features not in the current phase of IMPLEMENTATION-ROADMAP.md
- Do not skip measurement validation (tilt check, daylight check, hot-pixel check) — bad data contaminates the global map

## Next Recommended Move

Use this context plus the README and supporting docs to resume the next active task, then promote the repo beyond minimum-viable by capturing a dedicated handoff, roadmap, or discovery artifact.

<!-- portfolio-context:end -->
