import SwiftUI
import MapKit

/// Full-screen light pollution heatmap built on MKMapView.
///
/// Uses `UIViewRepresentable` because `SwiftUI.Map` does not support
/// custom `MKOverlayRenderer` subclasses (required for `HeatmapOverlayRenderer`).
///
/// - Heatmap mode: renders colored tile overlays from Supabase data.
/// - Points mode: removes overlays (stub for a future raw-pin layer).
struct MapView: View {

    @State private var viewModel: MapViewModel
    @State private var showRawPoints = false
    @State private var selectedTile: HeatmapTile?

    init(supabase: SupabaseService) {
        _viewModel = State(initialValue: MapViewModel(supabase: supabase))
    }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            MapKitView(viewModel: viewModel, showRawPoints: showRawPoints)
                .ignoresSafeArea()
                .accessibilityLabel("Light pollution map")
                .accessibilityHint("Interactive map showing light pollution measurements worldwide")

            VStack(alignment: .trailing, spacing: 8) {
                Picker("Display mode", selection: $showRawPoints) {
                    Text("Heatmap").tag(false)
                    Text("Points").tag(true)
                }
                .pickerStyle(.segmented)
                .frame(width: 180)
                .padding(.horizontal)
                .padding(.top, 56) // clear navigation bar
                .accessibilityLabel("Map display mode")
                .accessibilityHint("Switch between heatmap overlay and individual measurement points")

                if viewModel.isLoading {
                    ProgressView()
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(Circle())
                        .padding(.trailing)
                }

                if let errorMessage = viewModel.fetchError {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(.red.opacity(0.85))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .padding(.trailing)
                }
            }
        }
        .navigationTitle("Light Pollution Map")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: Binding(
            get: { selectedTile.map { IdentifiableTile(tile: $0) } },
            set: { selectedTile = $0?.tile }
        )) { item in
            TileInfoSheet(tile: item.tile)
                .presentationDetents([.medium])
        }
    }
}

// MARK: - UIViewRepresentable wrapper

private struct MapKitView: UIViewRepresentable {
    let viewModel: MapViewModel
    let showRawPoints: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    func makeUIView(context: Context) -> MKMapView {
        let map = MKMapView()
        map.delegate = context.coordinator
        map.overrideUserInterfaceStyle = .dark
        map.mapType = .hybrid
        map.showsUserLocation = true
        map.showsCompass = false

        // Default region: San Francisco area at ~5° span
        let region = MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.7749, longitude: -122.4194),
            span: MKCoordinateSpan(
                latitudeDelta: MapConstants.defaultRegionSpanDegrees,
                longitudeDelta: MapConstants.defaultRegionSpanDegrees
            )
        )
        map.setRegion(region, animated: false)
        return map
    }

    func updateUIView(_ map: MKMapView, context: Context) {
        let currentOverlays = map.overlays.compactMap { $0 as? HeatmapOverlay }
        let newOverlays = showRawPoints ? [] : viewModel.overlays

        // Only replace overlays if the set has changed (compare by cellLat as a proxy).
        let currentLats = currentOverlays.map(\.tile.cellLat)
        let newLats = newOverlays.map(\.tile.cellLat)
        guard currentLats != newLats else { return }

        map.removeOverlays(map.overlays)
        if !showRawPoints {
            map.addOverlays(newOverlays, level: .aboveRoads)
        }
    }

    // MARK: - Coordinator

    final class Coordinator: NSObject, MKMapViewDelegate {
        let viewModel: MapViewModel

        init(viewModel: MapViewModel) {
            self.viewModel = viewModel
        }

        func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
            Task { @MainActor in
                self.viewModel.regionDidChange(to: mapView.region)
            }
        }

        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let heatmapOverlay = overlay as? HeatmapOverlay {
                return HeatmapOverlayRenderer(overlay: heatmapOverlay)
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
}

// MARK: - Tile Info Sheet

private struct TileInfoSheet: View {
    let tile: HeatmapTile

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Tile Details")
                        .font(.headline)
                    Text(String(
                        format: "%.4f°N, %.4f°E",
                        tile.cellLat,
                        tile.cellLon
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                Spacer()
                BortleBadge(bortleClass: tile.avgBortle)
            }

            Divider()

            Grid(alignment: .leading, horizontalSpacing: 24, verticalSpacing: 12) {
                GridRow {
                    Label("Avg Brightness", systemImage: "moon.stars")
                        .gridColumnAlignment(.leading)
                    Text(String(format: "%.1f mag/arcsec²", tile.avgBrightness))
                        .foregroundStyle(.secondary)
                        .gridColumnAlignment(.leading)
                }
                GridRow {
                    Label("Measurements", systemImage: "chart.bar")
                    Text("\(tile.measurementCount)")
                        .foregroundStyle(.secondary)
                }
                GridRow {
                    Label("Avg Bortle", systemImage: "light.max")
                    Text("Class \(tile.avgBortle)")
                        .foregroundStyle(.secondary)
                }
            }
            .font(.subheadline)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Identifiable wrapper for sheet binding

private struct IdentifiableTile: Identifiable {
    let id = UUID()
    let tile: HeatmapTile
}
