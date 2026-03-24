# Nocturne — Implementation Roadmap

## Executive Summary

### What We're Building
Nocturne is an iOS citizen science instrument that measures night sky brightness using the iPhone camera sensor in manual exposure mode (ISO 1600, 4-second exposure, wide-angle lens). It converts raw pixel luminance to magnitudes per square arcsecond (mag/arcsec²) using a per-model calibration table cross-referenced against VIIRS satellite data. The emotional core of the app is a side-by-side comparison: the user's actual light-polluted sky vs. the same view under Bortle Class 1 conditions, rendered using real star positions from the bundled Hipparcos/Tycho-2 catalog and device orientation via CoreMotion. Every validated measurement uploads to a Supabase/PostGIS backend and appears on a global heatmap. Distribution: App Store, free, no monetization in v1.

### Riskiest Parts

**[HIGH] Camera calibration accuracy across iPhone models**
- Why: Each iPhone model (12, 13, 14, 15, 16, Pro variants) has a different sensor sensitivity, lens transmission, and noise floor. Without per-model calibration, readings will be systematically off by 0.5–2.0 mag/arcsec², making the crowdsourced data scientifically meaningless.
- Mitigation: Build the calibration lookup table in Phase 0 by cross-referencing known Bortle class sites with VIIRS/DNB satellite light pollution data. Use polynomial regression coefficients per model stored in `calibration_table.json`. Supported models: iPhone 12 through 16 Pro Max.
- Fallback: If a model isn't in the table, show a "calibration not available for your device" message and store the raw reading with an `uncalibrated: true` flag. Don't block the user — just tag the data.

**[HIGH] Measurement validation — rejecting bad readings**
- Why: Cloudy skies, indoor measurements, phone pointed at streetlights, and daytime readings will all corrupt the global dataset. Unlike a controlled instrument, users will inevitably make mistakes.
- Mitigation: 4-gate validation pipeline: (1) Solar altitude check via ephemeris — reject if sun > -6° below horizon. (2) Device tilt check via CMMotionManager — reject if phone isn't within 20° of zenith. (3) Hot-pixel detection — reject if >0.1% of pixels are at 255 luminance (streetlight in frame). (4) Open-Meteo cloud cover — tag measurements with cloud_cover_pct; flag readings where cloud_cover_pct > 50% as `cloudy: true` rather than rejecting (cloudy data is still valid, just different).
- Fallback: If Open-Meteo is unreachable, skip weather tagging and mark `weather_unknown: true`.

**[HIGH] SpriteKit star renderer performance at scale**
- Why: The "pristine sky" comparison view needs to render ~5,000 visible star sprites at 60fps on a device already running AVCaptureSession and CoreMotion. Memory pressure is real.
- Mitigation: Cap star sprites at 5,000 per scene. Pre-filter the SQLite catalog at query time by magnitude threshold for the current sky brightness. Use SKTexture atlas for star sprites (3 sizes: bright/medium/faint). Terminate AVCaptureSession before entering comparison view — camera and renderer don't need to coexist.
- Fallback: If FPS drops below 30 (monitored via CADisplayLink), reduce sprite count to 2,000 and show a note.

**[MEDIUM] Supabase free tier limits**
- Why: Supabase free tier caps at 500MB database size and 2GB egress/month. With crowdsourced data at ~500 bytes per measurement, 500MB supports ~1M measurements — sufficient for v1. But if the app gets featured, it could spike.
- Mitigation: Batch uploads (don't upload on every measurement, queue locally in GRDB and flush on Wi-Fi). Compress coordinates to 4 decimal places (≈11m precision, sufficient for heatmap). Upgrade to Supabase Pro ($25/mo) if approaching limits.
- Fallback: Rate-limit uploads client-side to 1 measurement per GPS cell per 24 hours.

**[MEDIUM] App Store review — camera + location permissions**
- Why: Apps requesting "always on" location or using camera in unusual ways attract extra scrutiny.
- Mitigation: Request `When In Use` location only (not Always). Camera permission string must explicitly state "to measure night sky brightness for citizen science." Include a privacy policy URL in the App Store listing before submission. Test on a real device — simulator camera access is broken.

### Shortest Path to Daily Personal Use
- **Phase 0 (Week 1):** Star catalog SQLite built, calibration table stubbed, Supabase schema live → nothing visual yet but all data is correct
- **Phase 1 (Week 2–3):** Camera measurement pipeline working, readings validated → Saagar can take his first real sky measurement
- **Phase 2 (Week 4–5):** Comparison view live, both sky renderers working → emotional core of the app is functional
- **Phase 3 (Week 6–7):** Map view live, measurements uploading, data flowing → full v1 citizen science loop closed
- **Phase 4 (Week 8):** Polish, onboarding, App Store prep → submission-ready

Phase 1 completion = 40% of the value (you can measure your sky). Phase 2 completion = 80% (you see what you're missing). Phase 3 = 100% (the citizen science mission is live).

---

## Architecture

### System Overview
```
[iPhone Camera]
    → AVCaptureSession (ISO 1600, 4s exposure, wide-angle)
    → RawPixelBuffer
    → MeasurementEngine
          → BrightnessCalculator (pixel avg → cd/m²)
          → CalibrationService (cd/m² → mag/arcsec² via model lookup table)
          → ValidationGate (tilt + daylight + hot-pixel + weather checks)
    → MeasurementRecord (local GRDB SQLite)
    → UploadQueue → Supabase REST API → PostGIS measurements table

[CoreLocation] → GPS coords + altitude → MeasurementRecord
[CoreMotion] → device attitude (pitch/roll/yaw) → SkyRenderer orientation
[Open-Meteo API] → cloud_cover_pct → MeasurementRecord weather tag

[MeasurementRecord]
    → ComparisonView
          → UserSkyRenderer (SpriteKit — stars visible at measured mag/arcsec²)
          → PristineSkyRenderer (SpriteKit — stars visible at 22.0 mag/arcsec²)
          → StarCatalogService (Hipparcos SQLite → filtered star list by magnitude threshold)

[Supabase PostGIS]
    → HeatmapService → MapKit MKOverlayRenderer → MapView
    → PublicDataAPI (future: open dataset endpoint)
```

### File Structure
```
Nocturne/
├── Nocturne.xcodeproj
├── Config.xcconfig                    # Supabase URL + anon key — excluded from git
├── .gitignore                         # Must include Config.xcconfig
├── CLAUDE.md
├── IMPLEMENTATION-ROADMAP.md
├── Nocturne/
│   ├── App/
│   │   ├── NocturneApp.swift          # @main entry point, environment setup
│   │   └── AppState.swift             # Global ObservableObject — nav state, user prefs
│   ├── Views/
│   │   ├── OnboardingView.swift       # First-launch tutorial: what the app does + permissions
│   │   ├── MeasurementView.swift      # Camera viewfinder + measurement flow
│   │   ├── ComparisonView.swift       # Side-by-side sky renderer
│   │   ├── MapView.swift              # Global heatmap
│   │   ├── HistoryView.swift          # Local measurement log
│   │   └── SettingsView.swift         # Device model info, calibration status, donation link
│   ├── ViewModels/
│   │   ├── MeasurementViewModel.swift # Owns measurement session state machine
│   │   ├── ComparisonViewModel.swift  # Owns star filter logic and scene assembly
│   │   └── MapViewModel.swift         # Owns heatmap tile fetching and rendering
│   ├── Services/
│   │   ├── CameraService.swift        # AVCaptureSession management, pixel buffer extraction
│   │   ├── MeasurementEngine.swift    # Pixel buffer → mag/arcsec² conversion pipeline
│   │   ├── CalibrationService.swift   # Per-model lookup table + interpolation
│   │   ├── ValidationGate.swift       # 4-gate measurement validation
│   │   ├── StarCatalogService.swift   # GRDB queries against bundled Hipparcos SQLite
│   │   ├── WeatherService.swift       # Open-Meteo cloud cover fetch
│   │   ├── SupabaseService.swift      # Upload queue + map tile fetch
│   │   └── LocationService.swift      # CLLocationManager wrapper
│   ├── Models/
│   │   ├── MeasurementRecord.swift    # Core data model + GRDB record conformance
│   │   ├── Star.swift                 # Star catalog row model
│   │   ├── CalibrationModel.swift     # Per-model calibration coefficients
│   │   └── HeatmapTile.swift          # Map tile model from Supabase
│   ├── Renderers/
│   │   ├── SkyScene.swift             # SKScene subclass — shared base for both renderers
│   │   ├── UserSkyScene.swift         # Renders stars visible at user's measured brightness
│   │   └── PristineSkyScene.swift     # Renders stars visible at 22.0 mag/arcsec²
│   ├── Resources/
│   │   ├── hipparcos_tycho2.sqlite    # Bundled star catalog (~15MB, mag ≤ 9.0)
│   │   ├── calibration_table.json     # Per-model calibration coefficients
│   │   ├── Assets.xcassets            # App icon, star sprite atlas
│   │   └── StarSprites.atlas/         # SKTexture atlas: star_bright.png, star_med.png, star_faint.png
│   ├── Constants.swift                # All magic numbers: ISO, exposure, magnitude thresholds, etc.
│   └── Info.plist                     # Permission strings: camera, location
├── NocturneTests/
│   ├── MeasurementEngineTests.swift   # Unit tests: pixel → cd/m² → mag/arcsec² math
│   ├── ValidationGateTests.swift      # Unit tests: all 4 validation gates
│   └── CalibrationServiceTests.swift  # Unit tests: per-model interpolation accuracy
└── NocturneUITests/
    └── MeasurementFlowUITest.swift    # UI test: measurement → comparison view transition
```

### Data Model

#### Local SQLite (GRDB) — `nocturne_local.sqlite`

```sql
-- Local measurement log
CREATE TABLE measurements (
    id              TEXT PRIMARY KEY,           -- UUID string
    measured_at     INTEGER NOT NULL,           -- Unix timestamp
    latitude        REAL NOT NULL,
    longitude       REAL NOT NULL,
    altitude_m      REAL NOT NULL,
    sky_brightness  REAL NOT NULL,             -- mag/arcsec², calibrated
    raw_brightness  REAL NOT NULL,             -- cd/m², pre-calibration
    iphone_model    TEXT NOT NULL,             -- e.g. "iPhone15,2" (machine identifier)
    iso_value       INTEGER NOT NULL,          -- always 1600
    exposure_s      REAL NOT NULL,             -- always 4.0
    calibration_ver TEXT NOT NULL,             -- calibration_table.json version used
    cloud_cover_pct INTEGER,                   -- 0–100, NULL if weather fetch failed
    is_cloudy       INTEGER NOT NULL DEFAULT 0, -- 1 if cloud_cover_pct > 50
    is_calibrated   INTEGER NOT NULL DEFAULT 1, -- 0 if model not in calibration table
    is_uploaded     INTEGER NOT NULL DEFAULT 0, -- upload queue flag
    uploaded_at     INTEGER,                   -- NULL until uploaded
    device_tilt_deg REAL NOT NULL,             -- degrees from zenith at capture
    bortle_class    INTEGER NOT NULL           -- 1–9, computed from sky_brightness
);
CREATE INDEX idx_measurements_uploaded ON measurements(is_uploaded);
CREATE INDEX idx_measurements_measured_at ON measurements(measured_at DESC);

-- Upload queue (measurements pending Supabase sync)
CREATE TABLE upload_queue (
    measurement_id  TEXT PRIMARY KEY REFERENCES measurements(id),
    queued_at       INTEGER NOT NULL DEFAULT (unixepoch()),
    attempts        INTEGER NOT NULL DEFAULT 0,
    last_attempt    INTEGER
);
```

#### Supabase (Postgres + PostGIS) — Remote

```sql
-- Enable PostGIS
CREATE EXTENSION IF NOT EXISTS postgis;

-- Global measurements table
CREATE TABLE measurements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    measured_at     TIMESTAMPTZ NOT NULL,
    location        GEOGRAPHY(POINT, 4326) NOT NULL,  -- PostGIS geography point
    altitude_m      REAL NOT NULL,
    sky_brightness  REAL NOT NULL,             -- mag/arcsec², calibrated
    iphone_model    TEXT NOT NULL,
    calibration_ver TEXT NOT NULL,
    cloud_cover_pct INTEGER,
    is_cloudy       BOOLEAN NOT NULL DEFAULT FALSE,
    is_calibrated   BOOLEAN NOT NULL DEFAULT TRUE,
    bortle_class    INTEGER NOT NULL CHECK (bortle_class BETWEEN 1 AND 9)
);

-- Spatial index for heatmap queries
CREATE INDEX idx_measurements_location ON measurements USING GIST (location);
CREATE INDEX idx_measurements_measured_at ON measurements (measured_at DESC);
CREATE INDEX idx_measurements_bortle ON measurements (bortle_class);

-- Row-level security: public read, anon insert only (no update/delete)
ALTER TABLE measurements ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Public read" ON measurements FOR SELECT USING (true);
CREATE POLICY "Anon insert" ON measurements FOR INSERT WITH CHECK (true);

-- Heatmap tile function: returns aggregated grid cells for bounding box
CREATE OR REPLACE FUNCTION heatmap_tiles(
    min_lat FLOAT, max_lat FLOAT,
    min_lon FLOAT, max_lon FLOAT,
    grid_size_deg FLOAT DEFAULT 0.1  -- ~11km at equator
)
RETURNS TABLE (
    cell_lat FLOAT,
    cell_lon FLOAT,
    avg_brightness FLOAT,
    measurement_count INTEGER,
    avg_bortle INTEGER
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        ROUND((ST_Y(location::geometry)::NUMERIC / grid_size_deg), 0)::FLOAT * grid_size_deg AS cell_lat,
        ROUND((ST_X(location::geometry)::NUMERIC / grid_size_deg), 0)::FLOAT * grid_size_deg AS cell_lon,
        AVG(sky_brightness)::FLOAT AS avg_brightness,
        COUNT(*)::INTEGER AS measurement_count,
        ROUND(AVG(bortle_class))::INTEGER AS avg_bortle
    FROM measurements
    WHERE location && ST_MakeEnvelope(min_lon, min_lat, max_lon, max_lat, 4326)
      AND is_calibrated = TRUE
    GROUP BY cell_lat, cell_lon;
END;
$$ LANGUAGE plpgsql;
```

### Swift Type Definitions

```swift
// Models/MeasurementRecord.swift
struct MeasurementRecord: Identifiable, Codable {
    let id: String                  // UUID
    let measuredAt: Date
    let latitude: Double
    let longitude: Double
    let altitudeM: Double
    let skyBrightness: Double       // mag/arcsec², calibrated
    let rawBrightness: Double       // cd/m²
    let iphoneModel: String         // e.g. "iPhone15,2"
    let isoValue: Int               // always 1600
    let exposureS: Double           // always 4.0
    let calibrationVer: String
    let cloudCoverPct: Int?
    let isCloudy: Bool
    let isCalibrated: Bool
    let deviceTiltDeg: Double
    let bortleClass: Int            // 1–9
}

// Models/Star.swift
struct Star: Identifiable {
    let id: Int                     // Hipparcos catalog number
    let ra: Double                  // Right ascension, degrees
    let dec: Double                 // Declination, degrees
    let vmag: Double                // Visual magnitude
    let colorIndex: Double?         // B-V color index for star color tinting
}

// Models/CalibrationModel.swift
struct CalibrationCoefficients: Codable {
    let iphoneModel: String         // Machine identifier, e.g. "iPhone15,2"
    let friendlyName: String        // e.g. "iPhone 15 Pro"
    let a: Double                   // y = a * log10(x) + b + c * temp_c
    let b: Double
    let c: Double                   // temperature coefficient (usually ~0 for room temp)
    let version: String             // calibration_table.json version
}

// Models/HeatmapTile.swift
struct HeatmapTile: Codable {
    let cellLat: Double
    let cellLon: Double
    let avgBrightness: Double       // mag/arcsec²
    let measurementCount: Int
    let avgBortle: Int
}

// Services/MeasurementEngine.swift — conversion constants
enum SkyBrightnessConstants {
    static let targetISO: Float = 1600
    static let targetExposure: Double = 4.0           // seconds
    static let pristineMagArcsec2: Double = 22.0      // Bortle Class 1
    static let urbanMinMagArcsec2: Double = 16.0      // Bortle Class 9
    static let nakedEyeLimitingMagOffset: Double = -5.0  // NELM ≈ SQM - 5 (approx)

    // Bortle class thresholds (mag/arcsec²)
    static let bortleThresholds: [(class: Int, minMag: Double)] = [
        (1, 21.75), (2, 21.5), (3, 21.25), (4, 20.5),
        (5, 19.5),  (6, 18.5), (7, 17.5),  (8, 16.5), (9, 0.0)
    ]
}
```

### API Contracts

#### External APIs

| Service | Endpoint | Method | Auth | Rate Limit | Purpose |
|---------|----------|--------|------|------------|---------|
| Open-Meteo | `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&hourly=cloudcover&forecast_days=1` | GET | None | ~10k/day free | Cloud cover % at measurement location/time |
| Supabase REST | `{SUPABASE_URL}/rest/v1/measurements` | POST | Anon key header | 500 req/s free tier | Upload measurement record |
| Supabase RPC | `{SUPABASE_URL}/rest/v1/rpc/heatmap_tiles` | POST | Anon key header | 500 req/s free tier | Fetch heatmap grid cells for visible map region |

#### Open-Meteo Response Shape (relevant fields)
```swift
struct OpenMeteoResponse: Codable {
    struct Hourly: Codable {
        let time: [String]
        let cloudcover: [Int]       // 0–100%
    }
    let hourly: Hourly
    // Extract cloudcover value for the hour closest to measurement time
}
```

### Dependencies

```bash
# Swift Package Manager — add in Xcode: File > Add Package Dependencies

# Supabase Swift SDK
https://github.com/supabase/supabase-swift  (version: 2.x)

# GRDB — SQLite ORM for local storage
https://github.com/groue/GRDB.swift  (version: 6.x)

# SpriteKit — built into iOS, no package needed

# No CocoaPods. No external UI libraries. Pure SwiftUI + native frameworks.
```

---

## Scope Boundaries

**In scope (v1):**
- Sky brightness measurement (single reading per session)
- Measurement validation (4-gate pipeline)
- Side-by-side comparison renderer (user sky vs. pristine sky)
- Local measurement history with GRDB
- Crowdsourced upload to Supabase
- Global heatmap (MapKit + Supabase RPC)
- Onboarding flow with permission requests
- Settings screen with calibration status

**Out of scope (v1, do not build):**
- Dark sky finder / nearest dark location recommendations
- Temporal tracking / per-location trend charts
- Tonight's sky events (meteor showers, ISS passes, conjunctions)
- Apple Watch complication
- School/classroom integration
- Gamification / achievements
- Donation in-app purchase
- Public data API endpoint
- Social sharing of measurements
- Multiple measurements per session

**Deferred to v2:**
- Dark sky finder using heatmap data
- Per-location longitudinal charts
- Celestial event overlay on comparison view
- Gamification (subtle achievements)
- Open dataset API

---

## Security & Credentials

- **Supabase URL + anon key:** Stored in `Config.xcconfig` (excluded from `.gitignore`). Loaded at build time via `Bundle.main.infoDictionary`. Never hardcoded in source. Xcode build config reads from `Config.xcconfig` via custom build settings `SUPABASE_URL` and `SUPABASE_ANON_KEY` injected into `Info.plist`.
- **Data leaving the device:** GPS coordinates (4 decimal places, ~11m precision), timestamp, sky brightness, iPhone model identifier, Bortle class, cloud cover %. No user identifiers, no email, no account system.
- **Anonymous uploads:** Measurements are uploaded anonymously. No auth, no account required. Row-level security allows anon INSERT but no UPDATE or DELETE.
- **Local data:** GRDB database stored in `Application Support` directory, not backed up to iCloud by default (set `isExcludedFromBackup = true` on the file URL).
- **No API key rotation needed:** Supabase anon key is designed to be public-safe with RLS enforced. The real secret is the service key, which never touches the client.

---

## Phase 0: Foundation (Week 1)

**Objective:** All data infrastructure in place — star catalog SQLite built, calibration table defined, local GRDB schema migrated, Supabase schema live with PostGIS. No UI. Verify everything by running unit tests.

**Tasks:**
1. Xcode project scaffolded with SwiftUI template, minimum deployment iOS 17.0. Add SPM packages: supabase-swift 2.x, GRDB.swift 6.x. — **Acceptance:** `swift build` succeeds with zero warnings.
2. `Config.xcconfig` created with `SUPABASE_URL` and `SUPABASE_ANON_KEY` placeholders; `.gitignore` updated to exclude it; `Info.plist` wired to read both via `$(SUPABASE_URL)` substitution. — **Acceptance:** `Bundle.main.infoDictionary?["SUPABASE_URL"]` returns non-nil string at runtime in simulator.
3. Download Hipparcos/Tycho-2 catalog from VizieR (I/239 + I/259). Write a one-time Python script to filter to visual magnitude ≤ 9.0, output `hipparcos_tycho2.sqlite` with schema: `(id INT, ra REAL, dec REAL, vmag REAL, bv REAL)`. Bundle the output into `Resources/`. — **Acceptance:** SQLite file is ≤ 18MB; `SELECT COUNT(*) FROM stars WHERE vmag <= 9.0` returns between 250,000 and 400,000 rows.
4. `calibration_table.json` created with coefficients for iPhone 12, 12 Pro, 13, 13 Pro, 14, 14 Pro, 15, 15 Pro, 16, 16 Pro (and Max variants where sensor differs). Initial coefficients stubbed from published iPhone sensor specs — will be refined post-launch with real-world calibration. Version field: `"1.0"`. — **Acceptance:** File parses into `[CalibrationCoefficients]` in a unit test with no decoding errors.
5. GRDB local schema: create `DatabaseManager.swift` that opens/creates `nocturne_local.sqlite` in `Application Support`, runs migrations, creates `measurements` and `upload_queue` tables per schema above. — **Acceptance:** `DatabaseManagerTests` creates a fresh DB, inserts 1 row, reads it back, all fields match.
6. Supabase project created (free tier). PostGIS extension enabled. Run SQL from Architecture → Data Model section (remote schema) in Supabase SQL editor. `heatmap_tiles` function deployed. RLS policies active. — **Acceptance:** Call `heatmap_tiles(37.0, 38.0, -122.5, -121.5, 0.1)` from Supabase SQL editor, returns empty array with no errors.
7. `SupabaseService.swift` skeleton: configure `SupabaseClient` with URL + anon key from `Info.plist`. Implement `uploadMeasurement(_ record: MeasurementRecord) async throws` and `fetchHeatmapTiles(for region: MKCoordinateRegion) async throws -> [HeatmapTile]`. — **Acceptance:** `SupabaseServiceTests` calls `uploadMeasurement` with a mock record and asserts no throw (requires real Supabase project credentials in test environment).
8. `MeasurementEngine.swift` core math: implement `pixelLuminanceToMagArcsec2(rawLuminance: Double, model: String, calibration: CalibrationCoefficients) -> Double`. Implement `bortleClass(from skyBrightness: Double) -> Int`. — **Acceptance:** `MeasurementEngineTests` asserts: raw luminance = 0.0005 cd/m², iPhone 15 Pro coefficients → output in range 19.0–21.0 mag/arcsec²; bortle class for 21.5 = 2; bortle class for 17.0 = 7.

**Verification Checklist:**
- [ ] `swift build` → zero errors, zero warnings
- [ ] `swift test` in NocturneTests → all 8 unit tests pass
- [ ] Supabase dashboard → `measurements` table exists with correct columns + RLS enabled
- [ ] Supabase SQL editor → `heatmap_tiles(...)` executes without error
- [ ] `hipparcos_tycho2.sqlite` bundles into app target and is readable at runtime

**Risks:**
- Hipparcos/Tycho-2 download format may require format conversion → Use VizieR's "CSV" export format; Python script handles column mapping → Fallback: use the pre-processed HYG Database (open source, GitHub) which is already SQLite-ready
- Supabase free tier may require credit card for new project → Check current signup flow; if required, $25/mo Pro is acceptable

---

## Phase 1: Camera Measurement Pipeline (Weeks 2–3)

**Objective:** Full measurement flow working end-to-end. User can point phone at sky, wait 4 seconds, get a calibrated sky brightness reading with Bortle class. Measurement is stored locally. Upload queue populated but not yet flushed.

**Tasks:**
1. `CameraService.swift`: `AVCaptureSession` configured with `.custom` exposure mode, ISO 1600, 4.0s exposure duration, wide-angle camera (`builtInWideAngleCamera`). Expose `captureFrame() async throws -> CVPixelBuffer`. Handle `AVAuthorizationStatus` — request permission if `.notDetermined`, throw `CameraError.denied` if `.denied`. — **Acceptance:** Running on a real device (not simulator), `captureFrame()` returns a non-nil `CVPixelBuffer`; EXIF metadata on the captured frame confirms ISO=1600, exposure=4.0s.
2. `MeasurementEngine.swift` pixel processing: implement `averageLuminance(from pixelBuffer: CVPixelBuffer) -> Double` by sampling a 240×240 center crop of the frame, computing the mean pixel value across all channels, converting to cd/m² using the known relationship for sRGB pixels: `cd_m2 = (meanPixelValue / 255.0)^2.2 * 80.0`. Implement hot-pixel detection: `hotPixelFraction(in pixelBuffer: CVPixelBuffer) -> Double` (fraction of pixels at 255). — **Acceptance:** `MeasurementEngineTests` with a synthetic all-128 pixel buffer → luminance ~21 cd/m² ± 5; all-255 buffer → hotPixelFraction = 1.0.
3. `ValidationGate.swift`: implement all 4 gates as `enum ValidationResult { case valid; case rejected(reason: ValidationFailure) }`. Gates: (1) solar altitude via `CLLocation` + `Date` → reject if sun < -6° elevation (use simple solar altitude formula, not SolarEventKit); (2) tilt from `CMMotionManager` → reject if device > 20° from vertical; (3) hot-pixel fraction > 0.01 → reject; (4) `WeatherService` cloud cover fetch → tag, don't reject. — **Acceptance:** `ValidationGateTests` asserts: daytime location → `.rejected(.daytime)`; tilt 45° → `.rejected(.deviceTilt)`; all-255 frame → `.rejected(.lightSource)`; clear night, correct tilt, clean frame → `.valid`.
4. `LocationService.swift`: `CLLocationManager` wrapper. `requestWhenInUseAuthorization()`. Expose `currentLocation() async throws -> CLLocation` with 10-second timeout. — **Acceptance:** On device, `currentLocation()` returns non-nil with accuracy < 100m within 10 seconds.
5. `WeatherService.swift`: fetch `https://api.open-meteo.com/v1/forecast?latitude={lat}&longitude={lon}&hourly=cloudcover&forecast_days=1`. Extract cloudcover % for the current hour from the `hourly.time` array. Return `Int?` (nil on network error). — **Acceptance:** `WeatherServiceTests` with coordinates (37.77, -122.41) → returns an Int between 0 and 100 (live API call, mark test `@available(*, skip)` in CI).
6. `MeasurementViewModel.swift`: state machine with states: `.idle → .preparingCamera → .capturing → .validating → .complete(MeasurementRecord) → .error(MeasurementError)`. Orchestrates `CameraService → MeasurementEngine → ValidationGate → CalibrationService → LocationService → WeatherService`. Saves to GRDB and enqueues in `upload_queue` on success. — **Acceptance:** Running full flow on device at night, outdoors → `MeasurementRecord` created in local SQLite with valid sky_brightness value.
7. `MeasurementView.swift`: camera viewfinder (`AVCaptureVideoPreviewLayer` via `UIViewRepresentable`), countdown timer (4s progress ring during capture), validation feedback (icons for each gate), result card showing: sky brightness in mag/arcsec², Bortle class badge, Bortle description, calibration indicator. — **Acceptance:** UI flow works end to end on device; rejected measurements show specific failure reason; successful measurement shows result card.

**Verification Checklist:**
- [ ] Take a measurement on a real iPhone outdoors at night → result card shows sky_brightness in range 14.0–22.0 mag/arcsec²
- [ ] Take a measurement indoors during daytime → app rejects with "Not dark enough" message
- [ ] Tilt phone 45° sideways → app rejects with "Point toward zenith" message
- [ ] Point at a lit streetlight → app rejects with "Light source in frame" message
- [ ] Successful measurement → `SELECT * FROM measurements` in GRDB returns 1 row with `is_uploaded = 0`

**Risks:**
- `AVCaptureSession` with 4-second exposure on iPhone: some models cap maximum exposure at 1/3s in `AVCaptureSession` (as opposed to the Photos app which uses longer exposures via a different pipeline. — Mitigation: Test on physical device immediately. If max exposure < 4s, use the maximum available and adjust calibration coefficients accordingly. Alternative: use `AVCapturePhotoCaptureDelegate` with `AVCapturePhotoSettings` and `AVCaptureAutoExposureBracketedStillImageSettings` to request longer exposure. This is a Phase 1 day-1 risk — test it first before building the rest of the pipeline.
- Solar altitude formula accuracy: simple formula may be off by ±1° → Sufficient for a 6° threshold; use Jean Meeus "Astronomical Algorithms" Chapter 25 formula

---

## Phase 2: Comparison View (Weeks 4–5)

**Objective:** The emotional core of the app. Side-by-side SpriteKit scenes showing "Your Sky" vs "Pristine Sky" using real star positions from Hipparcos, oriented to device compass heading + tilt.

**Tasks:**
1. `StarCatalogService.swift`: GRDB query against `hipparcos_tycho2.sqlite`. Method `starsVisible(above magnitude: Double, centerRA: Double, centerDec: Double, fieldDegrees: Double) -> [Star]`. Field of view for iPhone wide-angle ≈ 77° diagonal → use 80° to be safe. Cap results at 5,000 stars. Compute RA/Dec for device orientation using `CMMotionManager` attitude + `CLLocation` latitude + `Date` (local sidereal time calculation). — **Acceptance:** Query for magnitude ≤ 6.5, any sky position → returns 2,000–5,000 stars in < 50ms on device.
2. `SkyScene.swift` (SKScene base): accepts `[Star]` array, renders each as a sprite from `StarSprites.atlas`. Size and opacity keyed to visual magnitude: mag 1.0 = large bright sprite; mag 6.5 = tiny faint sprite. Color tint from B-V index: B-V < 0.0 = blue-white; B-V 0.5–1.0 = yellow; B-V > 1.5 = red-orange. Black background. — **Acceptance:** Scene renders 3,000 stars in simulator at ≥ 30fps (check with Instruments Time Profiler).
3. `UserSkyScene.swift`: extends `SkyScene`. Filters star list to stars visible at the user's measured sky brightness (limiting magnitude threshold). For mag/arcsec² = 18.0, limiting mag ≈ 4.5; for 20.0, limiting mag ≈ 5.5; for 22.0, limiting mag ≈ 6.5. Formula: `limitingMag = (skyBrightness - 13.5) * 0.33` (approximate, calibrated against NELM tables). — **Acceptance:** UserSkyScene with skyBrightness = 18.0 renders ≤ 200 stars; with 22.0 renders ≥ 2,000 stars.
4. `PristineSkyScene.swift`: extends `SkyScene`. Always renders at 22.0 mag/arcsec² (Bortle Class 1). Adds a Milky Way band: pre-rendered gradient overlay texture generated from FITS image data or a hand-crafted radial gradient approximating the Galactic plane. Add Andromeda (M31) as a soft glow ellipse at its correct RA/Dec (00h 42m 44s, +41° 16'). — **Acceptance:** PristineSkyScene shows recognizably more stars than UserSkyScene for any input skyBrightness < 21.0; Milky Way band visible as a luminous diagonal swath.
5. `ComparisonView.swift`: horizontal split layout. Left: `SpriteView(scene: userScene)` labeled "Your Sky". Right: `SpriteView(scene: pristineScene)` labeled "What You're Missing". Below: stat bar showing sky brightness, Bortle class, limiting magnitude, estimated # stars visible. Tap to go full-screen on either panel. Share button (exports a static screenshot of both panels side by side). — **Acceptance:** ComparisonView displays on device with both panels live; stat bar shows correct values from the MeasurementRecord; share sheet opens with a composite image.
6. `ComparisonViewModel.swift`: loads `MeasurementRecord`, computes sky orientation from `CMMotionManager` + `CLLocation` + `Date`, queries `StarCatalogService`, assembles both scenes. — **Acceptance:** View model transitions from measurement result → both scenes populated within 2 seconds on iPhone 14 or newer.

**Verification Checklist:**
- [ ] After a real measurement, ComparisonView opens and shows two populated star fields
- [ ] UserSkyScene shows dramatically fewer stars than PristineSkyScene for a Bortle 7+ reading
- [ ] Both scenes orient to the same patch of sky (same RA/Dec center point)
- [ ] Milky Way band visible in PristineSkyScene
- [ ] Share button produces a legible composite image in Camera Roll
- [ ] Instruments: no memory spikes > 200MB when both scenes are live

**Risks:**
- Sidereal time / RA-Dec-to-screen projection math: small bugs produce wildly wrong star placement → Write `AstrometryTests` with known star positions (Sirius at RA 6h 45m, Dec -16°) and verify it appears in the correct screen quadrant at a known time/location → Fallback: use a fixed default orientation (straight up = celestial north) if device attitude math is wrong; disclose this limitation
- SpriteKit memory with 5,000 sprites: may OOM on iPhone 12 → Test on iPhone 12 first; if needed, reduce cap to 2,500 for A14 chip and below

---

## Phase 3: Map + Upload Pipeline (Weeks 6–7)

**Objective:** The citizen science mission closes. Measurements upload to Supabase, heatmap renders on the global map. The app is a complete v1 product.

**Tasks:**
1. `SupabaseService.uploadMeasurement()`: implement with retry logic (3 attempts, exponential backoff). After successful upload: update `is_uploaded = 1`, `uploaded_at = now()` in GRDB, remove from `upload_queue`. — **Acceptance:** With network off, measurement queues locally; with network restored, `retryPendingUploads()` flushes the queue; Supabase dashboard shows the row.
2. Upload trigger in `AppState.swift`: on app foreground + network available, call `SupabaseService.retryPendingUploads()`. Use `NWPathMonitor` for network state. Only attempt uploads on Wi-Fi (not cellular) by default — add a settings toggle for cellular uploads. — **Acceptance:** Toggle cellular uploads off → uploads don't fire on LTE; turn on → uploads fire on LTE.
3. `SupabaseService.fetchHeatmapTiles(for region: MKCoordinateRegion)`: call `heatmap_tiles` RPC with bounding box. Parse into `[HeatmapTile]`. Cache results for 5 minutes (in-memory). — **Acceptance:** With 5 uploaded measurements, `fetchHeatmapTiles` for the SF Bay Area returns ≥ 1 tile; cache prevents re-fetch within 5 minutes.
4. `MapViewModel.swift`: observes `MKCoordinateRegion` changes from MapView, calls `fetchHeatmapTiles` on region-change-debounce (500ms). Converts `[HeatmapTile]` to `[MKOverlay]` for rendering. — **Acceptance:** Panning the map triggers fresh tile fetches (debounced); tiles appear within 2 seconds of settling.
5. `HeatmapOverlay.swift` + `HeatmapOverlayRenderer.swift` (`MKOverlayRenderer` subclass): renders each heatmap tile as a colored circle. Color gradient: `avgBrightness < 17.0` → deep red; `17–19` → orange-yellow; `19–21` → green; `> 21` → deep blue. Opacity keyed to `measurementCount` (more measurements = more opaque). — **Acceptance:** With ≥ 5 uploaded measurements, map shows colored circles at their correct geographic locations.
6. `MapView.swift`: dark-themed `MKMapView` (`.hybrid` style with `.dark` appearance). Toggle between "Heatmap" and "Raw Points" (individual measurement pins). Info panel on tile tap: avg brightness, Bortle class, measurement count, last measured date. — **Acceptance:** Map loads in < 3 seconds; tapping a heatmap tile shows an info bottom sheet with correct stats.
7. `HistoryView.swift`: list of all local measurements sorted by date desc. Each row: timestamp, location (reverse geocoded city name via `CLGeocoder`), sky brightness, Bortle badge, upload status indicator. Tap row → goes to ComparisonView re-rendering that measurement's star field. — **Acceptance:** After 3 measurements, HistoryView shows 3 rows; tapping row 1 opens ComparisonView for that measurement.

**Verification Checklist:**
- [ ] Upload 3 measurements from 3 different real locations → all 3 appear in Supabase `measurements` table
- [ ] Map view shows heatmap tiles at those locations
- [ ] Kill app, reopen → upload queue flushes previously queued measurements
- [ ] HistoryView shows all local measurements with correct Bortle badges
- [ ] Tapping a history row reopens ComparisonView for that specific measurement

**Risks:**
- PostGIS `heatmap_tiles` function slow on large datasets → Add `EXPLAIN ANALYZE` in Supabase SQL editor; ensure spatial index is used; if slow, add a `WHERE measured_at > now() - interval '1 year'` filter
- `CLGeocoder` rate limited (Apple limits to ~50 requests/min) → Cache geocoded results in GRDB; only geocode once per measurement, never on repeated HistoryView loads

---

## Phase 4: Polish + App Store Submission (Week 8)

**Objective:** App Store-ready. Privacy policy published, onboarding complete, all edge cases handled, TestFlight build distributed.

**Tasks:**
1. `OnboardingView.swift`: 4-screen onboarding shown on first launch only (`AppState.hasSeenOnboarding` persisted via `UserDefaults`). Screens: (1) What is light pollution + the emotional hook; (2) How measurement works (hold phone up, 4 seconds); (3) Permission requests (camera + location with explanatory text); (4) Your first measurement CTA. — **Acceptance:** Fresh install → onboarding shown; re-launch → skipped.
2. `SettingsView.swift`: iPhone model + calibration status ("Calibrated — coefficients v1.0"), measurement count, total uploads, cellular upload toggle, "View your data on the global map" link, donate link (opens Safari to a placeholder URL), privacy policy link, open source acknowledgments (GRDB, Supabase, Hipparcos catalog attribution). — **Acceptance:** All settings links open correctly; calibration status shows "Calibrated" for supported devices.
3. App icon designed: dark background, stylized Milky Way arc, single bright star. All required sizes generated for `Assets.xcassets`. — **Acceptance:** App icon appears in simulator home screen without pixelation.
4. Privacy policy: 1-page plain-language policy hosted on GitHub Pages or Netlify. Covers: data collected (anonymous measurements, no PII), how it's used (citizen science map), how to request deletion (email address provided). — **Acceptance:** URL accessible from Safari; App Store Connect privacy nutrition label filled out.
5. TestFlight build: archive + upload to App Store Connect. Invite 5 beta testers. Collect feedback on measurement accuracy (ask them to compare with a reference SQM meter if possible). — **Acceptance:** Build appears in TestFlight; 5 testers receive invite.
6. App Store listing: screenshots from all required device sizes (6.5", 5.5"), app preview video (15-second screen recording of measurement → comparison view), description emphasizing citizen science mission, keywords: light pollution, night sky, astronomy, citizen science, Bortle scale. — **Acceptance:** All required assets uploaded; listing passes App Store Connect validation (no missing assets).

**Verification Checklist:**
- [ ] Fresh install on TestFlight → onboarding flows correctly → first measurement completes
- [ ] Settings → all links open correctly
- [ ] Privacy policy URL loads in Safari
- [ ] App Store Connect → no validation errors on listing
- [ ] 3 TestFlight testers confirm they can complete a measurement

---

## Testing Strategy

### Unit Tests (NocturneTests)
- `MeasurementEngineTests`: pixel → cd/m² → mag/arcsec² conversion math with synthetic inputs
- `ValidationGateTests`: all 4 gates with edge-case inputs (boundary tilt angles, borderline daytime)
- `CalibrationServiceTests`: all supported iPhone models produce outputs in valid range (16.0–22.0)
- `DatabaseManagerTests`: GRDB insert/read/delete round-trip for `MeasurementRecord`
- `AstrometryTests`: sidereal time calculation at known date/location → Sirius in correct screen quadrant

### Integration Tests (manual, real device)
- Full measurement flow outdoors at night (Phase 1 verification)
- ComparisonView star count matches expected limiting magnitude for given sky brightness (Phase 2 verification)
- Upload → Supabase → heatmap render cycle (Phase 3 verification)

### Performance Targets
- `CameraService.captureFrame()`: < 5s wall time (4s exposure + 1s overhead)
- `StarCatalogService.starsVisible()`: < 50ms for any query
- `SkyScene` with 5,000 sprites: ≥ 30fps on iPhone 12, ≥ 60fps on iPhone 14+
- `SupabaseService.fetchHeatmapTiles()`: < 2s for a 5°×5° bounding box with < 10,000 measurements
- App cold launch to `MeasurementView`: < 2s
