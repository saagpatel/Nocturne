# Changelog

All notable changes to Nocturne are documented in this file.

## [Unreleased] — Phase 4: Polish & App Store Prep

### Added
- **Onboarding flow** — 3-step first-launch tutorial explaining what Nocturne does, how to take a measurement, and what the comparison reveals. Gated by `hasSeenOnboarding` UserDefaults flag; shown once on fresh install.
- **Accessibility labels** across all interactive elements — camera viewfinder, measure button, Bortle badges, comparison panels, stat bars, share button, map controls, history rows, and all action buttons now have `.accessibilityLabel` and `.accessibilityHint` modifiers for VoiceOver support.
- **Composite share screenshot** — share button in ComparisonView now renders both star field panels side-by-side with labels and a stat bar via `SKView.texture(from:)`, composited into a single UIImage and presented via `UIActivityViewController`.
- **App Store metadata** — `APPSTORE-METADATA.md` with app name, subtitle, description, keywords, category (Weather/Education), and pricing (free).
- **Changelog** — this file.

## [0.3.0] — Phase 3: Map + Upload Pipeline

### Added
- **MapView** — interactive global light pollution heatmap using `MKMapView` with custom `HeatmapOverlayRenderer`. Heatmap/Points mode toggle. Tile info bottom sheet with average brightness, Bortle class, and measurement count.
- **MapViewModel** — debounced region-change observer fetches heatmap tiles from Supabase RPC. In-memory tile cache with 5-minute TTL.
- **HeatmapOverlay + HeatmapOverlayRenderer** — `MKOverlayRenderer` subclass rendering colored tile cells keyed to sky brightness (blue = pristine, red = urban).
- **HeatmapTile model** — aggregated grid cell from Supabase `heatmap_tiles` PostGIS function.
- **HistoryView** — local measurement log sorted newest-first. Each row shows Bortle badge, reverse-geocoded location name, timestamp, sky brightness, and upload status. Tap to re-open ComparisonView.
- **HistoryViewModel** — loads measurements from GRDB, reverse-geocodes locations with `CLGeocoder` (cached), exposes location name lookup.
- **Upload pipeline** — `SupabaseService.retryPendingUploads()` flushes queued measurements with 3-attempt exponential backoff. `AppState` triggers on foreground + network. Wi-Fi-only by default with cellular toggle.
- **Network monitor** — `NWPathMonitor` in `AppState` tracks connectivity and Wi-Fi status.
- **Tab-based navigation** — 3-tab layout (Measure, Map, History) in `NocturneApp.swift`. Map and History gracefully degrade when Supabase or database are unavailable.

## [0.2.0] — Phase 2: Comparison View

### Added
- **ComparisonView** — side-by-side star field panels ("Your Sky" vs "What You're Missing") with tap-to-fullscreen and stat bar showing sky brightness, Bortle class, and limiting magnitude.
- **ComparisonViewModel** — loads star catalog, computes zenith RA/Dec, assembles both SpriteKit scenes.
- **SkyScene** — base `SKScene` subclass with gnomonic star projection, procedural radial gradient textures (bright/medium/faint), B-V color tinting, and magnitude-keyed opacity.
- **UserSkyScene** — filters stars to those visible at the user's measured sky brightness.
- **PristineSkyScene** — renders all stars visible under Bortle Class 1 conditions (22.0 mag/arcsec²). Includes Milky Way band and Andromeda (M31) glow.
- **StarCatalogService** — GRDB queries against bundled Hipparcos/Tycho-2 SQLite. Zenith RA/Dec computation from latitude, longitude, and date.
- **Astrometry utilities** — gnomonic projection, sidereal time, solar altitude calculations.
- **BortleBadge** — reusable colored badge component displaying Bortle class (1-9) with description.

## [0.1.0] — Phase 1: Camera Measurement Pipeline

### Added
- **MeasurementView** — camera viewfinder with "Measure Sky" button, capturing state with pulsing ring, result card with sky brightness and Bortle badge, rejection and error cards with actionable messages.
- **MeasurementViewModel** — 8-state measurement session state machine orchestrating camera, validation, calibration, location, and weather services.
- **CameraService** — `AVCaptureSession` with manual exposure (ISO 1600, 4s), wide-angle camera, pixel buffer extraction.
- **CameraPreview** — `UIViewRepresentable` wrapping `AVCaptureVideoPreviewLayer`.
- **MeasurementEngine** — pixel buffer center-crop luminance averaging, gamma-corrected cd/m² conversion, hot-pixel detection, sky brightness to Bortle class mapping.
- **CalibrationService** — per-model calibration lookup from `calibration_table.json`, polynomial conversion from raw luminance to mag/arcsec².
- **ValidationGate** — 4-gate measurement validation: solar altitude (civil twilight), device tilt (20° from zenith), hot-pixel fraction (1% threshold), cloud cover tagging.
- **LocationService** — `CLLocationManager` wrapper with 10-second timeout and accuracy filter.
- **WeatherService** — Open-Meteo cloud cover fetch for measurement location and time.

## [0.0.1] — Phase 0: Foundation

### Added
- Xcode project scaffolded — SwiftUI, iOS 17+, Swift 6 with strict concurrency.
- SPM dependencies: GRDB.swift 7.x (local SQLite), supabase-swift 2.x (backend).
- Bundled Hipparcos/Tycho-2 star catalog SQLite (~15MB, ~300K stars at mag <= 9.0).
- `calibration_table.json` with per-model coefficients (iPhone 12-16 Pro).
- `DatabaseManager` with GRDB migrations for `measurements` and `upload_queue` tables.
- `SupabaseService` skeleton with upload and heatmap tile fetch.
- `MeasurementEngine` core math: pixel luminance to mag/arcsec², Bortle class computation.
- `Constants.swift` with all named constants across 11 domains.
- `Config.xcconfig` for Supabase credentials (excluded from git).
- 56 unit tests across 10 test files.
