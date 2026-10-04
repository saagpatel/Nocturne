import SwiftUI

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
/// Numbers match APPSTORE-METADATA.md. Physical-result shots are deliberately
/// not simulated: this app has no mock camera input.
private enum AppStoreScreenshotMode: Int {
    case physicalResult = 1
    case physicalComparison = 2
    case history = 3
    case settings = 4

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

/// Uses the production History and Settings views without touching saved user
/// data, UserDefaults, permissions, camera, geocoding or community services.
private struct AppStoreScreenshotView: View {
    private let database: DatabaseManager
    @State private var selectedTab: Int
    @State private var shareMeasurements = false
    @State private var allowCellularUploads = false

    init(shot: AppStoreScreenshotMode) {
        do {
            // The plan allows an empty history. No timestamps or random inputs
            // are visible, and this isolated database is empty on every launch.
            database = try DatabaseManager.makeInMemory()
        } catch {
            fatalError("Cannot prepare screenshot history: \(error)")
        }
        _selectedTab = State(initialValue: shot == .history ? 3 : shot == .settings ? 4 : 1)
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                ContentUnavailableView(
                    "OPERATOR: capture on device",
                    systemImage: "camera",
                    description: Text("Capture a real night reading, then open See Your Sky for shots 1 and 2. Do not upload this screen.")
                )
            }
            .tabItem { Label("Measure", systemImage: "moon.stars.fill") }
            .tag(1)

            MapTab(supabase: nil)
                .tabItem { Label("Map", systemImage: "map.fill") }
                .tag(0)

            HistoryView(db: database)
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
