import SwiftUI

@main
struct NocturneApp: App {
    @State private var appState = AppState()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
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
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase == .active {
                Task { await appState.handleForeground() }
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
                    description: Text("Configure Supabase credentials to view the global heatmap.")
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
