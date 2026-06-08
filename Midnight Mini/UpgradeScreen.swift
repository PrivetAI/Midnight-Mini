import SwiftUI

// The storefront / between-shifts screen: start the next night, buy upgrades, unlock product lines.
struct StorefrontScreen: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        GeometryReader { geo in
            let maxW = min(geo.size.width, 760)
            ZStack {
                MarketTheme.night.ignoresSafeArea()
                VStack(spacing: 0) {
                    ScreenHeader(title: "Midnight Mini",
                                 subtitle: "Closed — prep for Night \(store.night)",
                                 trailing: AnyView(MoneyPill(amount: store.money)))
                        .padding(.horizontal, 16)
                        .padding(.top, 8)

                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 18) {
                            startCard
                            unlockSection
                            upgradeSection
                            Color.clear.frame(height: 20)
                        }
                        .padding(.horizontal, 16)
                        .padding(.top, 14)
                        .frame(maxWidth: maxW)
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private var startCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 14) {
                ClockIcon(size: 30, color: MarketTheme.neonAmber)
                VStack(alignment: .leading, spacing: 3) {
                    Text("Open Night \(store.night)")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.textHi)
                    Text("Shift cost \(marketMoney(store.nightOverhead)) overhead")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MarketTheme.textMid)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                miniStat("Shelves hold", "\(store.shelfCapacity)")
                miniStat("Restock/tap", "+\(store.restockPerTap)")
                miniStat("Lines", "\(store.stockedLines.count)")
            }
            NeonButton(title: "Start Shift", fill: MarketTheme.neonGreen) {
                store.startShift()
            }
        }
        .padding(16)
        .marketCard(fill: MarketTheme.panelHi)
    }

    private var unlockSection: some View {
        Group {
            if !store.lockedLinesForSale.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    sectionTitle("New Product Lines", icon: AnyView(CrateIcon(size: 18, color: MarketTheme.neonCyan)))
                    ForEach(store.lockedLinesForSale) { line in
                        let cost = store.lineUnlockCost(line)
                        HStack(spacing: 12) {
                            ProductGlyphView(glyph: line.glyph, size: 32, color: line.color)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(line.name)
                                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                                    .foregroundColor(MarketTheme.textHi)
                                Text("Sells ~\(marketMoney(line.basePrice)) each")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(MarketTheme.textMid)
                            }
                            Spacer()
                            Button(action: { store.unlockLine(line) }) {
                                Text(marketMoney(cost))
                                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                                    .foregroundColor(store.money >= cost ? MarketTheme.nightDeep : MarketTheme.textLow)
                                    .padding(.horizontal, 14).padding(.vertical, 8)
                                    .background(Capsule().fill(store.money >= cost ? MarketTheme.neonCyan : MarketTheme.panelHi))
                            }
                            .buttonStyle(.plain)
                            .disabled(store.money < cost)
                        }
                        .padding(12)
                        .marketCard()
                    }
                }
            }
        }
    }

    private var upgradeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            sectionTitle("Store Upgrades", icon: AnyView(UpgradeIcon(size: 18, color: MarketTheme.neonViolet)))
            ForEach(store.availableUpgrades, id: \.self) { kind in
                UpgradeRow(store: store, kind: kind)
            }
        }
    }

    private func sectionTitle(_ text: String, icon: AnyView) -> some View {
        HStack(spacing: 8) {
            icon
            Text(text)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(MarketTheme.textHi)
        }
    }

    private func miniStat(_ label: String, _ value: String) -> some View {
        VStack(spacing: 3) {
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(MarketTheme.neonCyan)
            Text(label.uppercased())
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.textLow)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 12).fill(MarketTheme.nightDeep))
    }
}

struct UpgradeRow: View {
    @ObservedObject var store: MarketStore
    let kind: UpgradeKind

    var body: some View {
        let lvl = store.level(kind)
        let cost = store.upgradeCost(kind)
        let maxed = cost == nil
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12).fill(MarketTheme.nightDeep).frame(width: 46, height: 46)
                kind.icon
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(kind.title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.textHi)
                    Text("Lv \(lvl)")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(MarketTheme.neonAmber)
                        .padding(.horizontal, 6).padding(.vertical, 1)
                        .background(Capsule().fill(MarketTheme.neonAmber.opacity(0.15)))
                }
                Text(kind.detail)
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(MarketTheme.textMid)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 6)
            if maxed {
                Text("MAX")
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.neonGreen)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(Capsule().fill(MarketTheme.neonGreen.opacity(0.15)))
            } else {
                Button(action: { store.buy(kind) }) {
                    Text(marketMoney(cost!))
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(store.canBuy(kind) ? MarketTheme.nightDeep : MarketTheme.textLow)
                        .padding(.horizontal, 14).padding(.vertical, 8)
                        .background(Capsule().fill(store.canBuy(kind) ? MarketTheme.neonViolet : MarketTheme.panelHi))
                }
                .buttonStyle(.plain)
                .disabled(!store.canBuy(kind))
            }
        }
        .padding(12)
        .marketCard()
    }
}
