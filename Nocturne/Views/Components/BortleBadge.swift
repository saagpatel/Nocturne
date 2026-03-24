import SwiftUI

/// Colored badge displaying a Bortle class (1–9) with description.
struct BortleBadge: View {
    let bortleClass: Int

    var body: some View {
        HStack(spacing: 12) {
            Text("B\(bortleClass)")
                .font(.system(size: 20, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 48, height: 48)
                .background(color)
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 2) {
                Text("Bortle Class \(bortleClass)")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(.white)
                Text(description)
                    .font(.system(size: 13, weight: .regular))
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }

    private var color: Color {
        switch bortleClass {
        case 1, 2: Color(red: 0.102, green: 0.137, blue: 0.494) // deep blue
        case 3, 4: Color(red: 0.0, green: 0.412, blue: 0.361)   // teal
        case 5, 6: Color(red: 0.961, green: 0.498, blue: 0.090) // amber
        case 7, 8: Color(red: 0.902, green: 0.318, blue: 0.0)   // orange-red
        default:   Color(red: 0.718, green: 0.110, blue: 0.110)  // red
        }
    }

    private var description: String {
        switch bortleClass {
        case 1: "Excellent Dark Sky"
        case 2: "Typical Dark Sky"
        case 3: "Rural Sky"
        case 4: "Rural/Suburban Transition"
        case 5: "Suburban Sky"
        case 6: "Bright Suburban Sky"
        case 7: "Suburban/Urban Transition"
        case 8: "City Sky"
        case 9: "Inner-City Sky"
        default: "Unknown"
        }
    }
}
