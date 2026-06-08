import SwiftUI

// A primary action button with the neon look.
struct NeonButton: View {
    let title: String
    var fill: Color = MarketTheme.neonAmber
    var textColor: Color = MarketTheme.nightDeep
    var enabled: Bool = true
    let action: () -> Void

    var body: some View {
        Button(action: { if enabled { action() } }) {
            Text(title)
                .font(.system(size: 17, weight: .heavy, design: .rounded))
                .foregroundColor(enabled ? textColor : MarketTheme.textLow)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(enabled ? fill : MarketTheme.panelHi)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(enabled ? fill.opacity(0.5) : MarketTheme.stroke, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

// A thin progress bar (custom; no system ProgressView).
struct ThinBar: View {
    var fraction: Double
    var color: Color
    var track: Color = MarketTheme.nightDeep
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule()
                    .fill(color)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}

// Money pill shown in headers.
struct MoneyPill: View {
    let amount: Int
    var icon: AnyView = AnyView(CoinIcon(size: 16))
    var color: Color = MarketTheme.money
    var body: some View {
        HStack(spacing: 6) {
            icon
            Text(marketMoney(amount))
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            Capsule().fill(MarketTheme.nightDeep)
        )
        .overlay(Capsule().stroke(MarketTheme.stroke.opacity(0.6), lineWidth: 1))
    }
}

// Reusable header used at the top of each screen.
struct ScreenHeader: View {
    let title: String
    var subtitle: String? = nil
    var trailing: AnyView? = nil
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            StoreMarkIcon(size: 30, color: MarketTheme.neonAmber)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.textHi)
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MarketTheme.textMid)
                }
            }
            Spacer()
            if let t = trailing { t }
        }
    }
}

// A small stat tile.
struct StatTile: View {
    let label: String
    let value: String
    var accent: Color = MarketTheme.neonCyan
    var icon: AnyView? = nil
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                if let ic = icon { ic }
                Text(label.uppercased())
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(MarketTheme.textLow)
            }
            Text(value)
                .font(.system(size: 22, weight: .heavy, design: .rounded))
                .foregroundColor(accent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .marketCard()
    }
}
