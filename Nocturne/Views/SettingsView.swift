import SwiftUI

struct SettingsView: View {
    @Binding var shareMeasurements: Bool
    @Binding var allowCellularUploads: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Uploads") {
                    Toggle("Contribute measurements", isOn: $shareMeasurements)
                    Text("Off by default. When enabled, Nocturne uploads measurement results and precise coordinates to the community dataset without a name or account.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)

                    Toggle("Allow cellular uploads", isOn: $allowCellularUploads)
                        .disabled(!shareMeasurements)
                    Text("Measurements wait for Wi-Fi when this is off.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Section("Data and support") {
                    Link("Privacy Policy", destination: URL(string: "https://github.com/saagpatel/Nocturne/blob/main/PRIVACY.md")!)
                    Link("Support", destination: URL(string: "https://github.com/saagpatel/Nocturne/issues")!)
                }

                Section("Acknowledgments") {
                    Text("Star display data: ESA/Gaia/DPAC")
                    Link(
                        "Gaia DR3 credit and citation",
                        destination: URL(string: "https://gea.esac.esa.int/archive/documentation/GDR3/Miscellaneous/sec_credit_and_citation_instructions/")!
                    )
                    Text("Built with GRDB and Supabase Swift.")
                        .foregroundStyle(.secondary)
                }

                Section {
                    LabeledContent("Version", value: appVersion)
                }
            }
            .navigationTitle("Settings")
        }
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "—"
        return "\(version) (\(build))"
    }
}
