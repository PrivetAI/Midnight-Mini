import SwiftUI

// MARK: - Night event banner (shown during a shift)

struct ModifierBanner: View {
    let modifier: NightModifier
    var dim: Bool = false
    var rush: Bool = false

    var body: some View {
        HStack(spacing: 7) {
            Circle().fill(modifier.accent).frame(width: 8, height: 8)
            Text(modifier.title.uppercased())
                .font(.system(size: 11, weight: .heavy, design: .rounded))
                .foregroundColor(modifier.accent)
            if rush {
                Text("· NOW")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.neonAmber)
            }
            if dim {
                Text("· DIM")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.danger)
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 5)
        .background(Capsule().fill(MarketTheme.nightDeep))
        .overlay(Capsule().stroke(modifier.accent.opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Contract chip (compact, used during a shift)

struct ContractChip: View {
    let contract: Contract
    let complete: Bool

    var body: some View {
        HStack(spacing: 7) {
            BadgeStar(size: 13, color: complete ? MarketTheme.neonGreen : MarketTheme.neonAmber)
            Text(contract.title)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(complete ? MarketTheme.neonGreen : MarketTheme.textMid)
                .lineLimit(1)
            if complete {
                Text("DONE")
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.nightDeep)
                    .padding(.horizontal, 6).padding(.vertical, 2)
                    .background(Capsule().fill(MarketTheme.neonGreen))
            }
        }
        .padding(.horizontal, 10).padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(MarketTheme.nightDeep))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous)
            .stroke((complete ? MarketTheme.neonGreen : MarketTheme.stroke).opacity(0.5), lineWidth: 1))
    }
}

// MARK: - Tonight preview (start card, between shifts)

struct TonightPreview: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let m = store.currentModifier {
                HStack(spacing: 8) {
                    Circle().fill(m.accent).frame(width: 9, height: 9)
                    Text(m.title)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .foregroundColor(m.accent)
                }
                Text(m.blurb)
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(MarketTheme.textMid)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                Text("A calm opening night — get your footing.")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(MarketTheme.textMid)
            }

            if let c = store.currentContract {
                HStack(spacing: 8) {
                    BadgeStar(size: 14, color: MarketTheme.neonAmber)
                    Text(c.title)
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .foregroundColor(MarketTheme.textHi)
                    Spacer(minLength: 6)
                    Text("\(marketMoney(c.rewardCash)) · \(c.rewardRep)★")
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.neonGreen)
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .marketCard()
    }
}

// MARK: - Story beat card

struct StoryBeatCard: View {
    let text: String
    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            StoreMarkIcon(size: 24, color: MarketTheme.neonViolet)
            Text(text)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(MarketTheme.textMid)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(MarketTheme.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(MarketTheme.neonViolet.opacity(0.4), lineWidth: 1))
    }
}

// MARK: - Order chips (used in the queue card and at the counter)

struct OrderChips: View {
    let order: [OrderLine]
    var glyphSize: CGFloat = 22
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 5 : 8) {
            ForEach(order) { ol in
                let line = Catalog.line(ol.lineId)
                HStack(spacing: 3) {
                    ProductGlyphView(glyph: line.glyph, size: glyphSize,
                                     color: ol.isDone ? line.color.opacity(0.35) : line.color)
                    Text("\(ol.filled)/\(ol.qty)")
                        .font(.system(size: compact ? 10 : 13, weight: .heavy, design: .rounded))
                        .foregroundColor(ol.isDone ? MarketTheme.neonGreen : MarketTheme.textHi)
                }
                .padding(.horizontal, compact ? 5 : 8)
                .padding(.vertical, compact ? 3 : 6)
                .background(Capsule().fill(MarketTheme.nightDeep))
                .overlay(Capsule().stroke(ol.isDone ? MarketTheme.neonGreen.opacity(0.6)
                                                     : MarketTheme.stroke.opacity(0.4), lineWidth: 1))
            }
        }
    }
}

// MARK: - Counter (drop target for the front customer's order)

struct CounterPanel: View {
    @ObservedObject var store: MarketStore
    var dragValid: Bool

    var body: some View {
        Group {
            if let c = store.frontReadyCustomer() {
                if c.quirk == .shoplifter {
                    ShoplifterCounter(store: store)
                } else {
                    ActiveCounter(customer: c, dragValid: dragValid)
                }
            } else {
                EmptyCounter(hasClerk: store.hasClerk)
            }
        }
    }
}

struct ActiveCounter: View {
    @ObservedObject var customer: MarketCustomer
    var dragValid: Bool

    var accent: Color {
        if let rid = customer.regularId, let r = Regular.byId(rid) { return r.accent }
        return customer.quirk.accent
    }
    var isRegular: Bool { customer.regularId != nil }

    var body: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) {
                ZStack {
                    Circle().fill(MarketTheme.nightDeep).frame(width: 44, height: 44)
                    Circle().stroke(accent.opacity(0.8), lineWidth: 2).frame(width: 44, height: 44)
                    if isRegular {
                        RegularPortraitIcon(size: 30, color: accent)
                    } else {
                        PersonIcon(size: 26, color: accent)
                    }
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(customer.displayName)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(accent)
                    Text(dragValid ? "Release to hand it over" : "Drag the items here")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MarketTheme.textMid)
                }
                Spacer()
            }
            OrderChips(order: customer.order, glyphSize: 26)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .fill(dragValid ? MarketTheme.neonGreen.opacity(0.14) : MarketTheme.panelHi))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(dragValid ? MarketTheme.neonGreen : accent.opacity(0.5),
                    lineWidth: dragValid ? 2.5 : 1.5))
    }
}

struct ShoplifterCounter: View {
    @ObservedObject var store: MarketStore
    var body: some View {
        Button(action: { store.stopFrontShoplifter() }) {
            HStack(spacing: 12) {
                PersonIcon(size: 28, color: MarketTheme.textHi)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Stop Shoplifter!")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.textHi)
                    Text("Tap before they slip out with stock")
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(MarketTheme.textHi.opacity(0.85))
                }
                Spacer()
                CloseIcon(size: 22, color: MarketTheme.textHi)
            }
            .padding(14)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(MarketTheme.danger.opacity(0.85)))
        }
        .buttonStyle(.plain)
    }
}

struct EmptyCounter: View {
    let hasClerk: Bool
    var body: some View {
        HStack {
            Text(hasClerk ? "Clerk is watching the counter…" : "No one at the counter")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(MarketTheme.textLow)
            Spacer()
            if hasClerk { PersonIcon(size: 20, color: MarketTheme.neonViolet) }
        }
        .padding(14)
        .frame(maxWidth: .infinity)
        .marketCard()
    }
}

// MARK: - Achievements section (Ledger)

struct AchievementsSection: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ACHIEVEMENTS (\(store.unlockedAchievements.count)/\(Achievement.all.count))")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.textLow)
            ForEach(Achievement.all) { a in
                let unlocked = store.unlockedAchievements.contains(a.id)
                HStack(spacing: 10) {
                    BadgeStar(size: 18, color: unlocked ? MarketTheme.neonAmber : MarketTheme.textLow.opacity(0.5))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(a.title)
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundColor(unlocked ? MarketTheme.textHi : MarketTheme.textMid)
                        Text(a.detail)
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(MarketTheme.textLow)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 6)
                    if unlocked {
                        Text("DONE")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(MarketTheme.neonGreen)
                    } else {
                        Text(marketMoney(a.reward))
                            .font(.system(size: 12, weight: .heavy, design: .rounded))
                            .foregroundColor(MarketTheme.textLow)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .marketCard()
    }
}

// MARK: - Regulars roster (Ledger)

struct RegularsRoster: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("REGULARS")
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.textLow)
            ForEach(Regular.roster) { r in
                let unlocked = store.unlockedRegulars.contains(where: { $0.id == r.id })
                let loyalty = store.regularLoyalty[r.id] ?? 0
                HStack(spacing: 10) {
                    RegularPortraitIcon(size: 34, color: unlocked ? r.accent : MarketTheme.textLow.opacity(0.45))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(unlocked ? r.name : "???")
                            .font(.system(size: 14, weight: .heavy, design: .rounded))
                            .foregroundColor(unlocked ? r.accent : MarketTheme.textLow)
                        Text(unlocked ? r.greeting : "Earn more reputation to meet them.")
                            .font(.system(size: 11, weight: .semibold, design: .rounded))
                            .foregroundColor(MarketTheme.textMid)
                            .lineLimit(1)
                    }
                    Spacer(minLength: 6)
                    HStack(spacing: 2) {
                        ForEach(0..<Regular.maxLoyalty, id: \.self) { i in
                            HeartIcon(size: 12, color: i < loyalty ? r.accent : MarketTheme.textLow.opacity(0.4),
                                      filled: i < loyalty)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .marketCard()
    }
}
