import SwiftUI

// The active-shift gameplay screen: drag products from shelves onto the customer's order.
struct ShiftScreen: View {
    @ObservedObject var store: MarketStore
    @State private var showAbandon = false

    // Drag-to-fill state.
    @State private var dragLineId: Int? = nil
    @State private var dragLocation: CGPoint = .zero
    @State private var dragValid: Bool = false
    @State private var counterFrame: CGRect = .zero

    var body: some View {
        GeometryReader { geo in
            // Clamp + center content so it never stretches/crops on wide canvases (iPad).
            let maxW = min(geo.size.width, UIScreen.main.bounds.width, 760)
            ZStack {
                MarketTheme.night.ignoresSafeArea()
                VStack(spacing: 12) {
                    // Top bar: night + timer + money
                    shiftTopBar
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    // Tonight's event + contract.
                    eventBar
                        .padding(.horizontal, 16)

                    // Customer queue (who's waiting).
                    CustomerQueueView(store: store)
                        .padding(.horizontal, 12)

                    // The counter — drop products here to fill the front order.
                    CounterPanel(store: store, dragValid: dragValid)
                        .padding(.horizontal, 16)
                        .background(
                            GeometryReader { g -> Color in
                                let f = g.frame(in: .global)
                                DispatchQueue.main.async {
                                    if counterFrame != f { counterFrame = f }
                                }
                                return Color.clear
                            }
                        )

                    // Shelves (drag sources / tap to restock) — an adaptive grid of compact
                    // blocks that always fits the area: more columns / smaller tiles as the
                    // catalog grows, so nothing ever runs off the screen.
                    VStack(spacing: 8) {
                        HStack {
                            sectionLabel("Shelves — tap to restock, drag up to give",
                                         icon: AnyView(CrateIcon(size: 16, color: MarketTheme.neonCyan)))
                            Spacer()
                            MoneyPill(amount: store.backroomBudget,
                                      icon: AnyView(CrateIcon(size: 14, color: MarketTheme.neonCyan)),
                                      color: MarketTheme.neonCyan)
                        }
                        .padding(.horizontal, 16)

                        GeometryReader { sg in
                            let count = store.stockedLines.count
                            let cols = shelfColumns(count: count, height: sg.size.height, width: sg.size.width)
                            let rows = max(1, Int(ceil(Double(count) / Double(cols))))
                            let tileH = min(88, max(56, (sg.size.height - CGFloat(rows - 1) * 8) / CGFloat(rows)))
                            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: cols),
                                      spacing: 8) {
                                ForEach(store.stockedLines) { line in
                                    ShelfTile(store: store, line: line,
                                              onDragChange: handleDragChange,
                                              onDragEnd: handleDragEnd)
                                        .frame(height: tileH)
                                }
                            }
                            .padding(.horizontal, 16)
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                        }
                    }

                    Button(action: { store.pauseShift(); showAbandon = true }) {
                        Text("End Shift Early")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(MarketTheme.textLow)
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 6)
                }
                .frame(maxWidth: maxW)
                .frame(maxWidth: .infinity)

                // Floating earnings overlay
                floatingOverlay

                // The dragged product "ghost" follows the finger.
                if let lid = dragLineId {
                    let line = Catalog.line(lid)
                    ProductGlyphView(glyph: line.glyph, size: 40, color: line.color)
                        .padding(8)
                        .background(Circle().fill(MarketTheme.panelHi))
                        .overlay(Circle().stroke(dragValid ? MarketTheme.neonGreen : MarketTheme.stroke,
                                                 lineWidth: 2))
                        .position(dragLocation)
                        .allowsHitTesting(false)
                }

                // Custom end-shift confirmation. The shift is paused while this is up, so
                // it stays responsive — a system .alert flickers under the 30fps timer.
                if showAbandon {
                    abandonOverlay
                        .zIndex(20)
                }
            }
        }
    }

    private var abandonOverlay: some View {
        ZStack {
            Color.black.opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                Text("End shift early?")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.textHi)
                Text("You'll keep what you earned so far and tally the night.")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(MarketTheme.textMid)
                    .multilineTextAlignment(.center)
                HStack(spacing: 12) {
                    Button(action: { showAbandon = false; store.resumeShift() }) {
                        Text("Keep Working")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(MarketTheme.nightDeep)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(MarketTheme.neonGreen))
                    }
                    .buttonStyle(.plain)
                    Button(action: { showAbandon = false; store.abandonShift() }) {
                        Text("End Shift")
                            .font(.system(size: 15, weight: .heavy, design: .rounded))
                            .foregroundColor(MarketTheme.danger)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 13)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(MarketTheme.danger.opacity(0.6), lineWidth: 1.5))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(22)
            .frame(maxWidth: 340)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(MarketTheme.panel))
            .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(MarketTheme.stroke, lineWidth: 1))
            .padding(28)
        }
    }

    // MARK: - Drag handlers

    private func handleDragChange(_ lineId: Int, _ loc: CGPoint) {
        dragLineId = lineId
        dragLocation = loc
        dragValid = counterFrame.contains(loc)
    }

    private func handleDragEnd(_ lineId: Int, _ loc: CGPoint) {
        if lineId >= 0 && counterFrame.contains(loc) {
            store.dropProduct(lineId)
        }
        dragLineId = nil
        dragValid = false
    }

    // Pick a column count so every shelf fits in the available height without scrolling:
    // add columns (shrinking tiles) as the catalog grows.
    private func shelfColumns(count: Int, height: CGFloat, width: CGFloat) -> Int {
        guard count > 0 else { return 1 }
        let tileH: CGFloat = 72
        let maxRows = max(1, Int((height + 8) / (tileH + 8)))
        let minCols = width > 560 ? 5 : 4
        let maxCols = width > 560 ? 8 : 6
        let needed = Int(ceil(Double(count) / Double(maxRows)))
        return min(maxCols, max(minCols, min(count, needed)))
    }

    // MARK: - Pieces

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
        .padding(.vertical, 2)
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
            Spacer().frame(height: 160)
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
