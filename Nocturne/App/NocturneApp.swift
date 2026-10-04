import SwiftUI
#if DEBUG
import GRDB
#endif

@main
struct NocturneApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            #if DEBUG
            if let shot = AppStoreScreenshotMode.requested {
                AppStoreScreenshotView(shot: shot)
            } else {
                appContent
            }
            #else
            appContent
            #endif
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await appState.handleForeground() }
            }
        }
    }

    private var appContent: some View {
        Group {
            if appState.hasSeenOnboarding {
                TabView {
                    MeasureTab(db: appState.databaseManager)
                        .tabItem {
                            Label("Measure", systemImage: "moon.stars.fill")
                        }

                    MapTab(supabase: appState.supabaseService)
                        .tabItem {
                            Label("Map", systemImage: "map.fill")
                        }

                    HistoryTab(db: appState.databaseManager)
                        .tabItem {
                            Label("History", systemImage: "clock.fill")
                        }

                    SettingsView(
                        shareMeasurements: $appState.shareMeasurements,
                        allowCellularUploads: $appState.allowCellularUploads
                    )
                        .tabItem {
                            Label("Settings", systemImage: "gearshape.fill")
                        }
                }
                .preferredColorScheme(.dark)
            } else {
                OnboardingView(hasSeenOnboarding: $appState.hasSeenOnboarding)
                    .preferredColorScheme(.dark)
            }
        }
    }
}

// MARK: - Tab content wrappers

/// Measurement tab — preserves its own NavigationStack.
private struct MeasureTab: View {
    let db: DatabaseManager?
    @State private var viewModel = MeasurementViewModel()
    @State private var navigationPath = NavigationPath()

    var body: some View {
        NavigationStack(path: $navigationPath) {
            MeasurementView(viewModel: viewModel, navigationPath: $navigationPath)
                .navigationDestination(for: MeasurementRecord.self) { record in
                    ComparisonView(viewModel: ComparisonViewModel(measurement: record))
                }
        }
    }
}

/// Map tab — only available when Supabase is configured.
private struct MapTab: View {
    let supabase: SupabaseService?

    var body: some View {
        NavigationStack {
            if let supabase {
                MapView(supabase: supabase)
            } else {
                ContentUnavailableView(
                    "Map Unavailable",
                    systemImage: "map",
                    description: Text("The community map is not available in this version.")
                )
                .navigationTitle("Map")
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
}

/// History tab.
private struct HistoryTab: View {
    let db: DatabaseManager?

    var body: some View {
        if let db {
            HistoryView(db: db)
        } else {
            ContentUnavailableView(
                "History Unavailable",
                systemImage: "clock",
                description: Text("Database could not be opened.")
            )
        }
    }
}

#if DEBUG
/// Numbers match APPSTORE-METADATA.md. No camera input is simulated.
private enum AppStoreScreenshotMode: Int {
    case result = 1
    case physicalComparison = 2
    case history = 3
    case comparison = 4

    static let requested: AppStoreScreenshotMode? = {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: "-AppStoreScreenshot") else {
            return nil
        }
        guard arguments.indices.contains(index + 1),
              let number = Int(arguments[index + 1]),
              let shot = AppStoreScreenshotMode(rawValue: number) else {
            fatalError("-AppStoreScreenshot requires a shot number from 1 through 4")
        }
        return shot
    }()
}

/// Fixed, synthetic night readings saved through the production GRDB path.
private enum AppStoreScreenshotFixtures {
    static let readings: [(record: MeasurementRecord, place: String)] = [
        reading(id: "screenshot-san-francisco", place: "San Francisco",
                date: "2026-09-15T05:00:00Z", latitude: 37.7749, longitude: -122.4194,
                altitude: 16, brightness: 18.3, cloudCover: 8),
        reading(id: "screenshot-joshua-tree", place: "Joshua Tree",
                date: "2026-09-12T05:30:00Z", latitude: 33.8734, longitude: -115.9010,
                altitude: 900, brightness: 21.3, cloudCover: 3),
        reading(id: "screenshot-death-valley", place: "Death Valley",
                date: "2026-09-08T06:00:00Z", latitude: 36.5054, longitude: -117.0794,
                altitude: 50, brightness: 21.8, cloudCover: 0),
        reading(id: "screenshot-point-reyes", place: "Point Reyes",
                date: "2026-09-04T05:15:00Z", latitude: 38.0690, longitude: -122.8069,
                altitude: 30, brightness: 20.7, cloudCover: 12)
    ]

    static let locationNames = Dictionary(uniqueKeysWithValues: readings.map {
        ($0.record.id, $0.place)
    })

    private static func reading(
        id: String, place: String, date: String, latitude: Double, longitude: Double,
        altitude: Double, brightness: Double, cloudCover: Int
    ) -> (record: MeasurementRecord, place: String) {
        guard let measuredAt = ISO8601DateFormatter().date(from: date) else {
            fatalError("Invalid screenshot fixture date: \(date)")
        }
        return (MeasurementRecord(
            id: id, measuredAt: measuredAt, latitude: latitude, longitude: longitude,
            altitudeM: altitude, skyBrightness: brightness,
            rawBrightness: pow(10, (brightness - 11.5) / -2.5),
            iphoneModel: "iPhone15,2", isoValue: Int(SkyBrightnessConstants.targetISO),
            exposureS: SkyBrightnessConstants.targetExposure,
            calibrationVer: CalibrationConstants.currentVersion,
            cloudCoverPct: cloudCover, isCloudy: false, isCalibrated: false,
            isUploaded: false, uploadedAt: nil, deviceTiltDeg: 2,
            bortleClass: MeasurementEngine.bortleClass(from: brightness)
        ), place)
    }
}

/// Uses production views and an isolated, seeded database without changing user
/// data or preferences, requesting permissions, or starting live services.
private struct AppStoreScreenshotView: View {
    private let database: DatabaseManager
    private let shot: AppStoreScreenshotMode
    private let comparisonRecord: MeasurementRecord
    @State private var selectedTab: Int
    @State private var measurementViewModel: MeasurementViewModel
    @State private var measurementPath = NavigationPath()
    @State private var shareMeasurements = false
    @State private var allowCellularUploads = false

    init(shot: AppStoreScreenshotMode) {
        self.shot = shot
        do {
            let database = try DatabaseManager.makeInMemory()
            try database.dbQueue.write { db in
                for fixture in AppStoreScreenshotFixtures.readings {
                    try fixture.record.insert(db)
                }
            }
            // Read back from the same store History loads, rather than displaying
            // a fixture that was never persisted.
            guard let record = try database.dbQueue.read({ db in
                try MeasurementRecord.order(Column("measured_at").desc).fetchOne(db)
            }) else {
                fatalError("Screenshot database has no readings")
            }
            self.database = database
            comparisonRecord = record
            _measurementViewModel = State(initialValue: MeasurementViewModel(
                screenshotRecord: record, database: database
            ))
        } catch {
            fatalError("Cannot prepare screenshot history: \(error)")
        }
        _selectedTab = State(initialValue: shot == .history || shot == .comparison ? 3 : 1)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack(path: $measurementPath) {
                if shot == .physicalComparison {
                    ContentUnavailableView(
                        "OPERATOR: capture on device",
                        systemImage: "camera",
                        description: Text("Capture a real night reading, then open See Your Sky for shot 2. Do not upload this screen.")
                    )
                } else {
                    MeasurementView(viewModel: measurementViewModel, navigationPath: $measurementPath)
                        .navigationDestination(for: MeasurementRecord.self) { record in
                            ComparisonView(viewModel: ComparisonViewModel(measurement: record))
                        }
                }
            }
            .tabItem { Label("Measure", systemImage: "moon.stars.fill") }
            .tag(1)

            MapTab(supabase: nil)
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(0)

            HistoryView(
                db: database,
                screenshotLocationNames: AppStoreScreenshotFixtures.locationNames,
                screenshotComparison: shot == .comparison ? comparisonRecord : nil
            )
                .tabItem { Label("History", systemImage: "clock.fill") }
                .tag(3)

            SettingsView(
                shareMeasurements: $shareMeasurements,
                allowCellularUploads: $allowCellularUploads
            )
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
            .tag(4)
        }
        .preferredColorScheme(.dark)
    }
}
#endif
