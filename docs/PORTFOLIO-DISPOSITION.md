# Nocturne — Portfolio Disposition

**Status:** Release Frozen (iOS App Store) — SwiftUI + AVFoundation
iPhone-camera-as-light-pollution-meter on `origin/main` with full
App Store submission scaffolding shipped (`APPSTORE-METADATA.md`,
fastlane `deliver`, refreshed App Store screenshots, App Store
archive prep, signing config), citizen-science framing
(crowdsourced global heatmap), per-device VIIRS calibration for
iPhone 12–16 Pro. **Fourth member of the iOS App Store cluster** —
and the **first cloud-backed iOS cluster member** (Calibrate /
Chromafield / Ghost Routes are local-first; Nocturne syncs
measurements to a crowdsourced global map).

> Disposition uses strict `origin/main` verification.
> **Introduces the "cloud-backed citizen-science" sub-shape** inside
> the iOS App Store cluster.

---

## Verification posture

This repo has **only `origin`** (`saagpatel/Nocturne`) — no
`legacy-origin` remote. Clean migration state. Local clone's `main`
is tracking `origin/main` correctly.

Specifically verified on `origin/main`:

- Tip: `e2353db` Merge pull request #4 from
  saagpatel/feat/portfolio-context-and-screenshots
- Substantive App Store prep commits on `origin/main`:
  - `e2353db` Merge #4: portfolio-context + screenshots refresh
  - `6b7604b` chore: add portfolio-context block and refresh App
    Store screenshots
  - `3a1c1d6` chore: add fastlane deliver config for App Store
    metadata upload
  - `bacfbac` Merge branch `feat/phase4-polish`
  - `822c7b6` chore: app store archive prep (signing, icons,
    screenshots)
- **Release scaffolding shipped on canonical main:**
  - `APPSTORE-METADATA.md`
  - `fastlane/` (deliver config)
  - `screenshots/` (refreshed per `6b7604b`)
  - DEVELOPMENT_TEAM + Privacy Manifest (per Phase 4 polish merge)
  - ExportOptions.plist
- App Store identity (from `APPSTORE-METADATA.md`):
  - Name: **Nocturne**, Subtitle: **Measure Light Pollution**
  - Bundle ID: `com.nocturne.app`, SKU: `NOCTURNE-001`
  - Categories: Weather (primary) + Education (secondary)
  - Age Rating: 4+, Price: Free, Availability: All territories
- Default branch: `main`

---

## Current state in one paragraph

Nocturne turns the iPhone camera into a calibrated scientific
instrument for measuring sky brightness on the Bortle scale (1-9,
the international dark-sky quality standard). Workflow: user points
camera at the night sky; AVFoundation captures a fixed-protocol
exposure (ISO 1600, 4-second, wide-angle); the calibration pipeline
maps raw pixel luminance to magnitudes per arc-second squared
(mag/arcsec²) using **per-device VIIRS satellite reference data**
for iPhone 12-16 Pro; measurement validators (tilt detection,
daylight rejection, hot-pixel filtering) reject invalid samples;
Open-Meteo weather tagging records cloud cover; reverse geocoding
records location; results post to a **crowdsourced global light
pollution heatmap** while also being stored offline-first with
automatic cloud sync. Per memory: Phases 0-4 complete, App Store
ready. The release commits on canonical main confirm: fastlane
deliver wired, screenshots refreshed, archive prep complete. The
operator has done the heavy lifting; only App Store Connect
submission remains.

For full detail see:
- `README.md` on `origin/main`
- `APPSTORE-METADATA.md`

---

## Why "Release Frozen (iOS App Store)" — fourth cluster member, first cloud-backed

The signature continues to hold across a fourth iOS app:

| Signal | Calibrate | Chromafield | Ghost Routes | **Nocturne** |
|---|---|---|---|---|
| DEVELOPMENT_TEAM wired | ✓ | ✓ | ✓ | ✓ (Phase 4 merge) |
| Privacy Manifest | ✓ | ✓ | ✓ | ✓ |
| APPSTORE-METADATA.md | ✓ | ✓ | ✓ | ✓ |
| fastlane deliver config | implied | `9341cc2` | `475374e` | `3a1c1d6` |
| ExportOptions.plist | ✓ | ✓ | ✓ | ✓ |
| Final icon | ✓ | `72c89b0` | `5055b4e` | per Phase 4 |
| Cloud backend | None | None | None | **Required — heatmap server** |

The new column is the distinguishing one. Calibrate, Chromafield,
and Ghost Routes are all local-first. Nocturne is the **first
cloud-backed iOS cluster member** — its core value proposition
("crowdsourced global light pollution map") requires a backend the
operator must operate.

This is a real sub-shape inside the iOS App Store cluster:

- **iOS App Store, local-first**: Calibrate / Chromafield /
  Ghost Routes
- **iOS App Store, cloud-backed**: **Nocturne**

Future iOS apps that require a backend (any "social", "crowdsourced",
or "synced across devices" feature) batch as the cloud-backed
sub-shape; they have additional operator concerns (server hosting,
data retention, GDPR/CCPA, abuse moderation).

---

## Cluster taxonomy update

| Cluster | Count | Sub-shapes |
|---|---|---|
| Signing (Apple desktop) | 23 | (no sub-shapes yet) |
| **iOS App Store** | **4** | local-first (3) / **cloud-backed (1, Nocturne)** |
| Static-host (web) | 3 | PWA / static SPA / SSR+Supabase |
| Self-hosted service | 1 | launchd + nginx |
| PyPI distribution | 2 | Release Frozen / Active |
| Local-first pipeline | 1 | (n/a) |
| Operator-tool / dogfood | 1 | (n/a) |
| Chrome MV3 extension | 1 | (no sub-shapes yet) |

The iOS App Store cluster now has internal sub-shape structure
matching the static-host cluster's (PWA / static SPA / SSR+Supabase).
This is consistent with the cluster's maturity at 4 members.

---

## Unblock trigger (operator)

When ready to ship publicly:

1. **App Store Connect record for `com.nocturne.app`** in Weather
   category. Citizen-science framing in the listing copy will help
   App Store editorial pickup.
2. **Backend hosting** — the crowdsourced heatmap needs a server.
   Operator concerns:
   - Where does measurement data POST to? (Notion-backed? Supabase?
     Vercel + Postgres? Cloudflare D1?)
   - Authentication model (anonymous / device-id-only / Sign in with
     Apple)
   - Rate limiting + spam / fake-measurement abuse posture
   - Data retention + GDPR/CCPA posture for cross-territory ship
3. **Privacy nutrition labels** — careful, this is a cloud-backed
   app:
   - Camera usage: "Used to capture night-sky calibration frames; not
     uploaded as raw images"
   - Location: "Linked to your account" or "Not Linked" depending on
     server design — verify exactly
   - Coarse vs precise location for the heatmap — coarse is the safer
     default
4. **VIIRS calibration data shipping** — if calibration coefficients
   are bundled into the app, the app size grows with each new
   supported iPhone. Verify shipping size + over-the-air update
   strategy if calibration data drifts.
5. **Open-Meteo dependency** — verify rate-limit / cost posture if
   measurement volume scales.
6. **Reverse-geocoding service** — likely Apple's MKLocalSearch /
   CLGeocoder; verify usage stays within Apple's daily quota for
   free apps.
7. **Required screenshots** — operator already refreshed per
   `6b7604b`.
8. **fastlane deliver dry run** before live upload.

Estimated operator time once App Store Connect record + backend
exist: ~6-8 hours (backend posture is the dominant cost; the iOS
side is the cheapest of the 4 cluster members because the operator
has done all the Apple-side work).

---

## Portfolio operating system instructions

| Aspect | Posture |
|---|---|
| Portfolio status | `Release Frozen (iOS App Store, cloud-backed)` |
| Distribution channel | **App Store Connect** (Weather category) |
| Review cadence | Suspend overdue counting |
| Resurface conditions | (a) Backend hosting decision made, (b) submits for App Store Review, (c) abuse / spam posture needs hardening, (d) Open-Meteo or VIIRS data source breakage, (e) v1.1 (additional iPhone model calibration) |
| Co-batch with | iOS App Store cluster: Calibrate / Chromafield / Ghost Routes / **Nocturne** — **now 4 repos** |
| Sub-shape | **First cloud-backed iOS cluster member.** Future cloud-backed iOS apps batch here as precedent. |
| Special concern | **Backend operational posture.** Local-first iOS apps don't have ongoing infrastructure cost. Nocturne does. This concern doesn't apply to other cluster members. |
| Special concern | **Citizen-science data quality.** Crowdsourced data is only valuable if the validators (tilt / daylight rejection / hot-pixel) reject fake or invalid submissions. Server-side validation is recommended in addition to on-device validators. |
| Special concern | **Per-device calibration scope (iPhone 12-16 Pro only).** App should clearly state supported devices in the App Store listing to avoid 1-star reviews from older-device users. |
| Special concern | **Privacy nutrition labels.** Different from local-first cluster siblings — must declare cloud sync, anonymized vs linked data, and location precision (coarse for heatmap is safer). |
| Special concern | **AVFoundation calibration drift.** Apple periodically changes camera ISP behavior in iOS updates. Calibration coefficients may need re-derivation after major iOS releases; verify before announcing. |

---

## Why this row introduces the cloud-backed iOS sub-shape

The first three iOS cluster members were intentionally local-first
(no backend, no analytics, no cloud). That kept the cluster's
operator-concern surface minimal. Nocturne breaks this by design —
its value proposition is crowdsourced. Naming the sub-shape now
prevents future iOS apps from being lumped together when they
shouldn't be:

- **Local-first iOS apps**: no backend, no GDPR/CCPA surface (beyond
  the on-device data), no abuse moderation. Operator concern surface
  ends at App Store Review.
- **Cloud-backed iOS apps**: backend hosting + abuse moderation +
  data retention + cross-territory data law + scaling cost. Operator
  concern surface continues indefinitely.

Treating these as the same sub-shape would lose the distinction.
Future iOS apps in the portfolio with social / sync / crowdsourced
features (none currently identified in remaining iOS candidates, but
Wavelength / RoomTone / Liminal need triage) classify by this axis.

---

## Reactivation procedure (for the next code session)

1. Verify `git branch -vv` shows `main` tracking `origin/main`.
   Already correct as of this disposition pass.
2. Review the local stash (`r13-nocturne-stash`) — contains untracked
   `.claude/`. Minimal carry-over.
3. **Open `Nocturne.xcodeproj` in Xcode** — confirm
   DEVELOPMENT_TEAM is still valid.
4. **Audit `APPSTORE-METADATA.md`** + verify screenshots in
   `screenshots/` match current UI.
5. **Verify backend hosting decision is captured somewhere** (not
   in this disposition because it's operator-product-decision-level)
   before submission.
6. **Verify VIIRS calibration coefficients** are current for the
   supported iPhone matrix (12-16 Pro).
7. **Test fastlane deliver dry run.**
8. **Run XCTest target.**

---

## Last known reference

| Field | Value |
|---|---|
| `origin/main` tip | `e2353db` Merge pull request #4 from saagpatel/feat/portfolio-context-and-screenshots |
| Last substantive commit | `3a1c1d6` chore: add fastlane deliver config for App Store metadata upload |
| Default branch | `main` |
| Build system | **iOS / Swift / SwiftUI / AVFoundation / XCTest** |
| Bundle ID | `com.nocturne.app` |
| Phases shipped | 0-4 per memory; Phase 4 polish merged on canonical main |
| Release scaffolding | **`APPSTORE-METADATA.md` + fastlane deliver + refreshed screenshots + ExportOptions.plist + Privacy Manifest + DEVELOPMENT_TEAM** |
| Distribution channel | **App Store Connect** (Weather + Education) |
| Tech distinguisher | AVFoundation calibrated camera capture (ISO 1600, 4-sec) + per-device VIIRS calibration (iPhone 12-16 Pro) + Bortle classifier + Open-Meteo weather integration + reverse geocoding + **crowdsourced backend heatmap** |
| Blocker | App Store Connect submission flow + **backend hosting decision** (operator-only) |
| Migration state | **No `legacy-origin` remote** — clean |
| Distinguishing feature | **Fourth iOS App Store cluster member AND first cloud-backed iOS sub-shape.** Crowdsourced heatmap requires backend. Different operator concern surface from local-first siblings. |
