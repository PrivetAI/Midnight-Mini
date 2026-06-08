import SwiftUI

// Fixed "night" palette. These colors are constant regardless of the device
// light/dark setting — the app forces its own appearance.
enum MarketTheme {
    // Deep night backgrounds
    static let night       = Color(red: 0.06, green: 0.07, blue: 0.13)   // app background
    static let nightDeep   = Color(red: 0.04, green: 0.05, blue: 0.09)   // darker panels
    static let panel       = Color(red: 0.12, green: 0.14, blue: 0.22)   // cards
    static let panelHi     = Color(red: 0.17, green: 0.20, blue: 0.30)   // raised cards
    static let stroke      = Color(red: 0.26, green: 0.30, blue: 0.44)

    // Neon-ish accents (a late-night convenience store sign)
    static let neonPink    = Color(red: 0.98, green: 0.32, blue: 0.62)
    static let neonCyan    = Color(red: 0.32, green: 0.82, blue: 0.95)
    static let neonAmber   = Color(red: 0.99, green: 0.74, blue: 0.27)
    static let neonGreen   = Color(red: 0.42, green: 0.86, blue: 0.55)
    static let neonViolet  = Color(red: 0.62, green: 0.50, blue: 0.96)

    // Text
    static let textHi      = Color(red: 0.95, green: 0.96, blue: 0.99)
    static let textMid     = Color(red: 0.72, green: 0.76, blue: 0.86)
    static let textLow     = Color(red: 0.50, green: 0.55, blue: 0.66)

    // Money / status
    static let money       = Color(red: 0.55, green: 0.92, blue: 0.66)
    static let danger      = Color(red: 0.96, green: 0.40, blue: 0.42)
}

// Card container styling reused across screens.
struct MarketCard: ViewModifier {
    var fill: Color = MarketTheme.panel
    var corner: CGFloat = 18
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(fill)
            )
            .overlay(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .stroke(MarketTheme.stroke.opacity(0.6), lineWidth: 1)
            )
    }
}

extension View {
    func marketCard(fill: Color = MarketTheme.panel, corner: CGFloat = 18) -> some View {
        self.modifier(MarketCard(fill: fill, corner: corner))
    }
}

// Formats a money value as a currency-ish string without locale dependence.
func marketMoney(_ value: Int) -> String {
    if value >= 1_000_000 {
        let m = Double(value) / 1_000_000.0
        return "$" + String(format: "%.1fM", m)
    }
    if value >= 10_000 {
        let k = Double(value) / 1_000.0
        return "$" + String(format: "%.1fk", k)
    }
    // group thousands manually
    let s = String(value)
    if s.count <= 3 { return "$" + s }
    var out = ""
    var count = 0
    for ch in s.reversed() {
        if count != 0 && count % 3 == 0 { out.append(",") }
        out.append(ch)
        count += 1
    }
    return "$" + String(out.reversed())
}
