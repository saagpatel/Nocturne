import SwiftUI

/// Displays the user's past sky brightness measurements sorted newest-first.
///
/// Tapping a row navigates to `ComparisonView` for that measurement.
/// Each row shows the Bortle class badge, reverse-geocoded location name,
/// timestamp, sky brightness value, and upload status.
struct HistoryView: View {

    @State private var viewModel: HistoryViewModel
    @State private var navigationPath = NavigationPath()

    init(db: DatabaseManager) {
        _viewModel = State(initialValue: HistoryViewModel(db: db))
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if viewModel.isLoading && viewModel.measurements.isEmpty {
                    ProgressView("Loading history…")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.measurements.isEmpty {
                    ContentUnavailableView(
                        "No Measurements Yet",
                        systemImage: "moon.stars",
                        description: Text("Take your first measurement to see it here.")
                    )
                } else {
                    List(viewModel.measurements) { record in
                        MeasurementRow(
                            record: record,
                            locationName: viewModel.locationName(for: record)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            navigationPath.append(record)
                        }
                        .listRowBackground(Color(.systemGroupedBackground))
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("History")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: MeasurementRecord.self) { record in
                ComparisonView(viewModel: ComparisonViewModel(measurement: record))
            }
        }
        .task {
            await viewModel.loadMeasurements()
        }
    }
}

// MARK: - Row

private struct MeasurementRow: View {
    let record: MeasurementRecord
    let locationName: String

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        HStack(spacing: 12) {
            BortleBadge(bortleClass: record.bortleClass)

            VStack(alignment: .leading, spacing: 4) {
                Text(locationName)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)

                Text(Self.dateFormatter.string(from: record.measuredAt))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "%.1f", record.skyBrightness))
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.primary)

                HStack(spacing: 4) {
                    Image(
                        systemName: record.isUploaded
                            ? "checkmark.icloud"
                            : "icloud.slash"
                    )
                    .font(.caption2)
                    .foregroundStyle(record.isUploaded ? .green : .secondary)

                    Text("mag/arcsec²")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
