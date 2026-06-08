import SwiftUI

struct NightMarketLoadingScreen: View {
    @State private var glow = false
    var body: some View {
        ZStack {
            MarketTheme.night.ignoresSafeArea()
            VStack(spacing: 22) {
                StoreMarkIcon(size: 96, color: MarketTheme.neonAmber)
                    .shadow(color: MarketTheme.neonAmber.opacity(glow ? 0.7 : 0.2), radius: glow ? 22 : 8)
                Text("Midnight Mini")
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.textHi)
                Text("Opening up…")
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(MarketTheme.textMid)
                // Custom pulsing dots
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Circle()
                            .fill(MarketTheme.neonCyan)
                            .frame(width: 9, height: 9)
                            .opacity(glow ? 1 : 0.3)
                            .animation(.easeInOut(duration: 0.6).repeatForever().delay(Double(i) * 0.18), value: glow)
                    }
                }
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                glow = true
            }
        }
    }
}
