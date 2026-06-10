import SwiftUI

// A single customer card in the queue.
struct CustomerCard: View {
    @ObservedObject var customer: MarketCustomer
    let isFront: Bool
    let line: ProductLine

    var accentColor: Color {
        if let rid = customer.regularId, let r = Regular.byId(rid) { return r.accent }
        return customer.quirk.accent
    }
    var isShoplifter: Bool { customer.quirk == .shoplifter }
    var isRegular: Bool { customer.regularId != nil }

    var body: some View {
        VStack(spacing: 8) {
            // Avatar — regulars get a portrait, others a silhouette.
            ZStack {
                Circle()
                    .fill(MarketTheme.nightDeep)
                    .frame(width: 52, height: 52)
                Circle()
                    .stroke(accentColor.opacity(0.8), lineWidth: isFront ? 2.5 : 1.5)
                    .frame(width: 52, height: 52)
                if isRegular {
                    RegularPortraitIcon(size: 34, color: accentColor)
                } else {
                    PersonIcon(size: 30, color: accentColor)
                }
            }

            // Order bubble (shoplifters show a warning instead of an order)
            if isShoplifter {
                Text("!")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.danger)
                    .padding(.horizontal, 12).padding(.vertical, 4)
                    .background(Capsule().fill(MarketTheme.danger.opacity(0.18)))
            } else if customer.ready {
                HStack(spacing: 4) {
                    ProductGlyphView(glyph: line.glyph, size: 20, color: line.color)
                    Text("x\(customer.quantity)")
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.textHi)
                }
                .padding(.horizontal, 8).padding(.vertical, 4)
                .background(Capsule().fill(MarketTheme.panelHi))
            } else {
                Text("…")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(MarketTheme.textMid)
                    .padding(.horizontal, 10).padding(.vertical, 4)
                    .background(Capsule().fill(MarketTheme.panelHi))
            }

            Text(customer.displayName)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(accentColor)
                .lineLimit(1)

            // Patience bar
            if customer.ready {
                ThinBar(fraction: customer.patienceFraction,
                        color: patienceColor,
                        height: 5)
                    .frame(width: 60)
            } else {
                ThinBar(fraction: 1, color: MarketTheme.textLow, height: 5)
                    .frame(width: 60)
            }
        }
        .padding(10)
        .frame(width: 92)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(isFront ? MarketTheme.panelHi : MarketTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(isFront ? accentColor : MarketTheme.stroke.opacity(0.4),
                        lineWidth: isFront ? 2 : 1)
        )
    }

    var patienceColor: Color {
        let f = customer.patienceFraction
        if f > 0.5 { return MarketTheme.neonGreen }
        if f > 0.25 { return MarketTheme.neonAmber }
        return MarketTheme.danger
    }
}

// Horizontal scrolling queue of customers.
struct CustomerQueueView: View {
    @ObservedObject var store: MarketStore

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                if store.queue.isEmpty {
                    EmptyQueueHint()
                } else {
                    ForEach(Array(store.queue.enumerated()), id: \.element.id) { idx, c in
                        CustomerCard(customer: c,
                                     isFront: c.id == store.frontReadyCustomer()?.id,
                                     line: Catalog.line(c.wantLineId))
                    }
                }
            }
            .padding(.horizontal, 4)
            .padding(.vertical, 4)
        }
    }
}

struct EmptyQueueHint: View {
    var body: some View {
        HStack(spacing: 8) {
            PersonIcon(size: 22, color: MarketTheme.textLow)
            Text("Quiet for now…")
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(MarketTheme.textLow)
        }
        .padding(.horizontal, 16).padding(.vertical, 24)
        .frame(maxWidth: .infinity)
    }
}
