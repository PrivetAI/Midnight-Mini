import SwiftUI

// The active-shift gameplay screen.
struct ShiftScreen: View {
    @ObservedObject var store: MarketStore
    @State private var showAbandon = false

    var body: some View {
        GeometryReader { geo in
            // Clamp width to avoid iPad over-wide cropping; center content.
            let maxW = min(geo.size.width, 760)
            let columns = geo.size.width > 560 ? 4 : 3

            ZStack {
                MarketTheme.night.ignoresSafeArea()
                VStack(spacing: 0) {
                    // Top bar: night + timer + money
                    shiftTopBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Tonight's event + contract.
                    eventBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Customer queue
                            VStack(alignment: .leading, spacing: 8) {
                                sectionLabel("Customers", icon: AnyView(PersonIcon(size: 16, color: MarketTheme.neonPink)))
                                CustomerQueueView(store: store)
                            }

                            // Serve button (front customer)
                            serveSection

                            // Shelves
                            VStack(alignment: .leading, spacing: 8) {
                                HStack {
                                    sectionLabel("Shelves — tap to restock", icon: AnyView(CrateIcon(size: 16, color: MarketTheme.neonCyan)))
                                    Spacer()
                                    MoneyPill(amount: store.backroomBudget,
                                              icon: AnyView(CrateIcon(size: 14, color: MarketTheme.neonCyan)),
                                              color: MarketTheme.neonCyan)
                                }
                                ShelfGrid(store: store, columns: columns)
                            }

                            Button(action: { showAbandon = true }) {
                                Text("End Shift Early")
                                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                                    .foregroundColor(MarketTheme.textLow)
                            }
                            .buttonStyle(.plain)
                            .padding(.top, 4)

                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 12)
                        .frame(maxWidth: maxW)
                        .frame(maxWidth: .infinity)
                    }
                }

                // Floating earnings overlay
                floatingOverlay
            }
            .alert(isPresented: $showAbandon) {
                Alert(title: Text("End shift early?"),
                      message: Text("You'll keep what you earned so far and tally the night."),
                      primaryButton: .destructive(Text("End Shift")) { store.abandonShift() },
                      secondaryButton: .cancel(Text("Keep Working")))
            }
        }
    }

    private var shiftTopBar: some View {
        HStack(spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text("NIGHT \(store.night)")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.neonViolet)
                HStack(spacing: 5) {
                    ClockIcon(size: 14, color: timerColor)
                    Text(timeString)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(timerColor)
                }
            }
            Spacer()
            MoneyPill(amount: store.shiftEarnings,
                      icon: AnyView(CoinIcon(size: 15)),
                      color: MarketTheme.money)
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder private var eventBar: some View {
        VStack(spacing: 6) {
            if let m = store.currentModifier {
                HStack {
                    ModifierBanner(modifier: m, dim: store.dimNow, rush: store.rushActive)
                    Spacer()
                }
            }
            if let c = store.currentContract {
                ContractChip(contract: c, complete: store.contractComplete)
            }
        }
    }

    private var serveSection: some View {
        VStack(spacing: 8) {
            if let front = store.frontReadyCustomer() {
                if front.quirk == .shoplifter {
                    // A shoplifter at the counter — tap to stop them.
                    Button(action: { store.serveFront() }) {
                        HStack(spacing: 12) {
                            PersonIcon(size: 28, color: MarketTheme.textHi)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Stop Shoplifter!")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(MarketTheme.textHi)
                                Text("Tap before they slip out with stock")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(MarketTheme.textHi.opacity(0.8))
                            }
                            Spacer()
                            CloseIcon(size: 22, color: MarketTheme.textHi)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(MarketTheme.danger.opacity(0.85))
                        )
                    }
                    .buttonStyle(.plain)
                } else {
                    let line = Catalog.line(front.wantLineId)
                    let available = store.shelves[front.wantLineId] ?? 0
                    let canServe = available > 0
                    Button(action: { store.serveFront() }) {
                        HStack(spacing: 12) {
                            ProductGlyphView(glyph: line.glyph, size: 30, color: line.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Serve \(front.displayName)")
                                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                                    .foregroundColor(MarketTheme.nightDeep)
                                Text("\(front.quantity)x \(line.name)  ·  on shelf: \(available)")
                                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                                    .foregroundColor(MarketTheme.nightDeep.opacity(0.7))
                            }
                            Spacer()
                            CoinIcon(size: 22, color: MarketTheme.nightDeep)
                        }
                        .padding(.horizontal, 16).padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(canServe ? MarketTheme.money : MarketTheme.danger.opacity(0.85))
                        )
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    Text(store.hasClerk ? "Clerk is watching the counter…" : "No one ready at the counter")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(MarketTheme.textLow)
                    Spacer()
                    if store.hasClerk {
                        PersonIcon(size: 20, color: MarketTheme.neonViolet)
                    }
                }
                .padding(.horizontal, 16).padding(.vertical, 14)
                .marketCard()
            }
        }
    }

    private var floatingOverlay: some View {
        VStack {
            Spacer()
            ZStack {
                ForEach(store.floatingEvents) { ev in
                    Text(ev.text)
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(ev.color)
                        .opacity(min(1, ev.life))
                        .offset(y: CGFloat(ev.offset) - 60)
                }
            }
            .frame(height: 1)
            Spacer().frame(height: 120)
        }
        .allowsHitTesting(false)
    }

    private func sectionLabel(_ text: String, icon: AnyView) -> some View {
        HStack(spacing: 6) {
            icon
            Text(text)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.textMid)
        }
    }

    private var timeString: String {
        let t = Int(ceil(store.timeLeft))
        let m = t / 60
        let s = t % 60
        return String(format: "%d:%02d", m, s)
    }

    private var timerColor: Color {
        if store.timeLeft <= 10 { return MarketTheme.danger }
        if store.timeLeft <= 25 { return MarketTheme.neonAmber }
        return MarketTheme.neonCyan
    }
}
