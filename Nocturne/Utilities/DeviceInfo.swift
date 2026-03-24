import Foundation

enum DeviceInfo {

    /// Returns the machine identifier (e.g. "iPhone17,1" for iPhone 16 Pro).
    /// Returns "Simulator" when running in the iOS Simulator.
    static var machineIdentifier: String {
        #if targetEnvironment(simulator)
        return "Simulator"
        #else
        var systemInfo = utsname()
        uname(&systemInfo)
        return withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(cString: $0)
            }
        }
        #endif
    }

    /// Whether the current device has calibration coefficients available.
    static var isCalibrated: Bool {
        CalibrationService.coefficients(for: machineIdentifier) != nil
    }
}
