import Foundation
import Network
import os

/// Monitors network connectivity and triggers pending upload retries.
@Observable
@MainActor
final class AppState {
    private(set) var isConnected: Bool = false
    private(set) var isOnWiFi: Bool = false

    @ObservationIgnored
    private let monitor = NWPathMonitor()
    @ObservationIgnored
    private let monitorQueue = DispatchQueue(label: "com.nocturne.network-monitor")
    @ObservationIgnored
    private let logger = Logger(subsystem: "com.nocturne.app", category: "AppState")

    let databaseManager: DatabaseManager?
    let supabaseService: SupabaseService?

    /// Persisted user preference for cellular uploads.
    var allowCellularUploads: Bool {
        get { UserDefaults.standard.bool(forKey: "allowCellularUploads") }
        set { UserDefaults.standard.set(newValue, forKey: "allowCellularUploads") }
    }

    init() {
        self.databaseManager = try? DatabaseManager.makeDefault()
        // Only initialize Supabase if properly configured.
        // Gracefully skip if Config.xcconfig is not set up.
        if let urlString = Bundle.main.infoDictionary?["SUPABASE_URL"] as? String,
           let url = URL(string: urlString),
           let anonKey = Bundle.main.infoDictionary?["SUPABASE_ANON_KEY"] as? String,
           !urlString.contains("your-project") {
            self.supabaseService = SupabaseService(url: url, anonKey: anonKey)
        } else {
            self.supabaseService = nil
        }
        startNetworkMonitor()
    }

    private func startNetworkMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.isConnected = path.status == .satisfied
                self.isOnWiFi = path.usesInterfaceType(.wifi)
            }
        }
        monitor.start(queue: monitorQueue)
    }

    /// Called when app returns to foreground. Triggers pending upload flush if network allows.
    func handleForeground() async {
        guard isConnected else { return }
        guard isOnWiFi || allowCellularUploads else {
            logger.info("Network available but not on Wi-Fi; cellular uploads disabled")
            return
        }
        await retryPendingUploads()
    }

    private func retryPendingUploads() async {
        guard let db = databaseManager, let supabase = supabaseService else { return }
        await supabase.retryPendingUploads(db: db.dbQueue)
    }
}
