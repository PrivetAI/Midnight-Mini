import SwiftUI

// Stats / ledger screen.
struct StatsScreen: View {
    @ObservedObject var store: MarketStore
    @State private var showReset = false

    var body: some View {
        GeometryReader { geo in
            let maxW = min(geo.size.width, 760)
            ZStack {
                MarketTheme.night.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScreenHeader(title: "Ledger", subtitle: "Your run so far")
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            HStack(spacing: 12) {
                                StatTile(label: "Cash", value: marketMoney(store.money),
                                         accent: MarketTheme.money,
                                         icon: AnyView(CoinIcon(size: 16)))
                                StatTile(label: "Night", value: "\(store.night)",
                                         accent: MarketTheme.neonViolet,
                                         icon: AnyView(ClockIcon(size: 16, color: MarketTheme.neonViolet)))
                            }
                            HStack(spacing: 12) {
                                StatTile(label: "Best Night", value: marketMoney(store.bestNightEarnings),
                                         accent: MarketTheme.neonAmber,
                                         icon: AnyView(StatsIcon(size: 16, color: MarketTheme.neonAmber)))
                                StatTile(label: "Served", value: "\(store.lifetimeServed)",
                                         accent: MarketTheme.neonCyan,
                                         icon: AnyView(PersonIcon(size: 16, color: MarketTheme.neonCyan)))
                            }
                            HStack(spacing: 12) {
                                StatTile(label: "Lifetime Earned", value: marketMoney(store.lifetimeEarned),
                                         accent: MarketTheme.neonGreen,
                                         icon: AnyView(StatsIcon(size: 16, color: MarketTheme.neonGreen)))
                                StatTile(label: "Reputation", value: "\(store.reputation)★",
                                         accent: MarketTheme.neonAmber,
                                         icon: AnyView(BadgeStar(size: 16, color: MarketTheme.neonAmber)))
                            }

                            // Reputation-driven roster of neighborhood regulars
                            RegularsRoster(store: store)

                            // Lifetime achievements
                            AchievementsSection(store: store)

                            // Quirk legend
                            quirkLegend

                            Button(action: { showReset = true }) {
                                Text("Reset Progress")
                                    .font(.system(size: 14, weight: .bold, design: .rounded))
                                    .foregroundColor(MarketTheme.danger)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(RoundedRectangle(cornerRadius: 14).stroke(MarketTheme.danger.opacity(0.5), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)

                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .frame(maxWidth: maxW)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .alert(isPresented: $showReset) {
                Alert(title: Text("Reset everything?"),
                      message: Text("This clears your cash, night, and all upgrades."),
                      primaryButton: .destructive(Text("Reset")) { store.resetProgress() },
                      secondaryButton: .cancel())
            }
        }
    }

    private var quirkLegend: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NIGHT CUSTOMERS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.textLow)
            ForEach(CustomerQuirk.allCases.filter { !$0.isSpecial }, id: \.self) { q in
                HStack(spacing: 10) {
                    PersonIcon(size: 18, color: q.accent)
                    Text(q.title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(q.accent)
                        .frame(width: 92, alignment: .leading)
                    Text(quirkBlurb(q))
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(MarketTheme.textMid)
                        .fixedSize(horizontal: false, vertical: true)
                    Spacer(minLength: 0)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .marketCard()
    }

    private func quirkBlurb(_ q: CustomerQuirk) -> String {
        switch q {
        case .ordinary:   return "Steady shopper, fair pay."
        case .impatient:  return "Short fuse; rush bonus if quick."
        case .bigSpender: return "Buys more, pays generously."
        case .browser:    return "Decides after a moment."
        case .nightOwl:   return "Cheerful, tips big when fast."
        case .haggler:    return "Talks the price down a little."
        case .tourist:    return "Patient and generous; takes a beat."
        case .kid:        return "Quick, small order, modest pay."
        case .hoarder:    return "Grabs a big stack at once."
        case .regular:    return "A familiar neighborhood face."
        case .shoplifter: return "Stop them before they slip out."
        }
    }
}
