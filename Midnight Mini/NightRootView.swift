import SwiftUI

struct NightRootView: View {
    @StateObject private var store = MarketStore()
    @State private var selectedTab = 0
    @State private var showSettings = false

    var body: some View {
        ZStack {
            MarketTheme.night.ignoresSafeArea()

            if store.phase == .shift {
                // Full-screen shift; no tab bar to keep focus.
                ShiftScreen(store: store)
                    .transition(.opacity)
            } else {
                tabbedContent
            }

            // Tally overlay sits above everything when a shift ends.
            if store.phase == .tally, let tally = store.lastTally {
                TallyOverlay(store: store, tally: tally)
                    .transition(.opacity)
                    .zIndex(10)
            }
        }
        .preferredColorScheme(.dark) // anchor to our fixed night palette
        .animation(.easeInOut(duration: 0.25), value: store.phase)
        .sheet(isPresented: $showSettings) {
            NightSettingsView(store: store)
        }
    }

    private var tabbedContent: some View {
        VStack(spacing: 0) {
            Group {
                switch selectedTab {
                case 0:
                    StorefrontScreen(store: store)
                case 1:
                    StatsScreen(store: store)
                default:
                    StorefrontScreen(store: store)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            customTabBar
        }
    }

    private var customTabBar: some View {
        HStack(spacing: 0) {
            tabButton(index: 0, label: "Store",
                      icon: AnyView(StoreMarkIcon(size: 24, color: selectedTab == 0 ? MarketTheme.neonAmber : MarketTheme.textLow)))
            tabButton(index: 1, label: "Ledger",
                      icon: AnyView(StatsIcon(size: 24, color: selectedTab == 1 ? MarketTheme.neonGreen : MarketTheme.textLow)))
            Button(action: { showSettings = true }) {
                VStack(spacing: 4) {
                    GearIcon(size: 24, color: MarketTheme.textLow)
                    Text("Settings")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(MarketTheme.textLow)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.plain)
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(
            MarketTheme.nightDeep
                .overlay(Rectangle().frame(height: 1).foregroundColor(MarketTheme.stroke.opacity(0.4)), alignment: .top)
                .edgesIgnoringSafeArea(.bottom)
        )
    }

    private func tabButton(index: Int, label: String, icon: AnyView) -> some View {
        Button(action: { selectedTab = index }) {
            VStack(spacing: 4) {
                icon
                Text(label)
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(selectedTab == index ? MarketTheme.textHi : MarketTheme.textLow)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// Gear icon for settings (custom shape).
struct GearIcon: View {
    var size: CGFloat = 24
    var color: Color = MarketTheme.textLow
    var body: some View {
        Canvas { ctx, sz in
            let c = CGPoint(x: sz.width/2, y: sz.height/2)
            let outer = sz.width * 0.42
            let inner = sz.width * 0.30
            var p = Path()
            let teeth = 8
            for i in 0..<(teeth*2) {
                let a = CGFloat(i) * .pi / CGFloat(teeth)
                let r = i % 2 == 0 ? outer : inner
                let pt = CGPoint(x: c.x + cos(a)*r, y: c.y + sin(a)*r)
                if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
            }
            p.closeSubpath()
            ctx.fill(p, with: .color(color))
            ctx.fill(Path(ellipseIn: CGRect(x: c.x - sz.width*0.14, y: c.y - sz.width*0.14, width: sz.width*0.28, height: sz.width*0.28)), with: .color(MarketTheme.nightDeep))
        }
        .frame(width: size, height: size)
    }
}

// End-of-shift results overlay.
struct TallyOverlay: View {
    @ObservedObject var store: MarketStore
    let tally: ShiftTally

    var body: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("Night \(tally.night) Closed")
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.textHi)

                VStack(spacing: 12) {
                    tallyRow("Earned", marketMoney(tally.earnings), MarketTheme.money)
                    tallyRow("Customers served", "\(tally.served)", MarketTheme.neonCyan)
                    tallyRow("Walked out", "\(tally.missed)", tally.missed > 0 ? MarketTheme.danger : MarketTheme.textMid)
                    Rectangle().fill(MarketTheme.stroke.opacity(0.4)).frame(height: 1)
                    tallyRow("Cash on hand", marketMoney(store.money), MarketTheme.neonAmber)
                }
                .padding(16)
                .frame(maxWidth: .infinity)
                .background(RoundedRectangle(cornerRadius: 16).fill(MarketTheme.nightDeep))

                NeonButton(title: "Open Next Night", fill: MarketTheme.neonGreen) {
                    store.continueAfterTally()
                }
            }
            .padding(22)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MarketTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .stroke(MarketTheme.stroke, lineWidth: 1)
            )
            .padding(28)
        }
    }

    private func tallyRow(_ label: String, _ value: String, _ color: Color) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(MarketTheme.textMid)
            Spacer()
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(color)
        }
    }
}
