import SwiftUI

// A single product shelf: shows the product, stock level, and a tap-to-restock action.
struct ShelfTile: View {
    @ObservedObject var store: MarketStore
    let line: ProductLine

    var stock: Int { store.shelves[line.id] ?? 0 }
    var capacity: Int { store.shelfCapacity }
    var fraction: Double { capacity > 0 ? Double(stock) / Double(capacity) : 0 }

    var lowStock: Bool { fraction <= 0.25 }

    var body: some View {
        Button(action: { store.restock(line.id) }) {
            VStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(MarketTheme.nightDeep)
                        .frame(height: 54)
                    ProductGlyphView(glyph: line.glyph, size: 36, color: stock > 0 ? line.color : line.color.opacity(0.3))
                    if stock == 0 {
                        Text("OUT")
                            .font(.system(size: 11, weight: .heavy, design: .rounded))
                            .foregroundColor(MarketTheme.danger)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(MarketTheme.danger.opacity(0.18)))
                            .offset(y: 18)
                    }
                }
                Text(line.name)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(MarketTheme.textHi)
                    .lineLimit(1)
                // Stock indicator
                HStack(spacing: 5) {
                    ThinBar(fraction: fraction,
                            color: lowStock ? MarketTheme.danger : line.color,
                            height: 6)
                    Text("\(stock)")
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundColor(lowStock ? MarketTheme.danger : MarketTheme.textMid)
                        .frame(width: 22, alignment: .trailing)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MarketTheme.panel)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(lowStock ? MarketTheme.danger.opacity(0.7) : MarketTheme.stroke.opacity(0.5),
                            lineWidth: lowStock ? 1.5 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// Grid of all stocked shelves.
struct ShelfGrid: View {
    @ObservedObject var store: MarketStore
    let columns: Int

    var body: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
        LazyVGrid(columns: cols, spacing: 10) {
            ForEach(store.stockedLines) { line in
                ShelfTile(store: store, line: line)
            }
        }
    }
}
