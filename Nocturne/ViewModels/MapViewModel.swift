import MapKit
import os

/// Manages heatmap tile fetching for the map view.
///
/// Region changes are debounced by `MapConstants.mapDebounceMilliseconds` before
/// issuing a network request, preventing excessive calls during pan/zoom gestures.
@Observable
@MainActor
final class MapViewModel {

    // MARK: - Observable State

    private(set) var overlays: [HeatmapOverlay] = []
    private(set) var isLoading = false
    private(set) var fetchError: String?

    // MARK: - Private

    @ObservationIgnored
    private var debounceTask: Task<Void, Never>?

    @ObservationIgnored
    private let supabase: SupabaseService

    @ObservationIgnored
    private let logger = Logger(subsystem: "com.nocturne.app", category: "MapViewModel")

    // MARK: - Init

    init(supabase: SupabaseService) {
        self.supabase = supabase
    }

    // MARK: - Region Updates

    /// Call when the visible map region changes.
    /// Cancels any in-flight debounce task and schedules a new fetch after the debounce delay.
    func regionDidChange(to region: MKCoordinateRegion) {
        debounceTask?.cancel()
        debounceTask = Task {
            try? await Task.sleep(for: .milliseconds(MapConstants.mapDebounceMilliseconds))
            guard !Task.isCancelled else { return }
            await fetchTiles(for: region)
        }
    }

    // MARK: - Private Fetch

    private func fetchTiles(for region: MKCoordinateRegion) async {
        let minLat = region.center.latitude - region.span.latitudeDelta / 2.0
        let maxLat = region.center.latitude + region.span.latitudeDelta / 2.0
        let minLon = region.center.longitude - region.span.longitudeDelta / 2.0
        let maxLon = region.center.longitude + region.span.longitudeDelta / 2.0

        isLoading = true
        fetchError = nil
        defer { isLoading = false }

        do {
            let tiles = try await supabase.fetchHeatmapTiles(
                minLat: minLat,
                maxLat: maxLat,
                minLon: minLon,
                maxLon: maxLon,
                gridSize: MapConstants.tileGridSizeDegrees
            )
            overlays = tiles.map { HeatmapOverlay(tile: $0) }
            logger.info("Fetched \(tiles.count) heatmap tile(s) for region")
        } catch {
            fetchError = error.localizedDescription
            logger.error("Failed to fetch heatmap tiles: \(error)")
        }
    }
}
