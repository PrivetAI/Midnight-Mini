import SwiftUI

// A single product shelf: tap to restock, drag the glyph onto the counter to hand it over.
struct ShelfTile: View {
    @ObservedObject var store: MarketStore
    let line: ProductLine
    var onDragChange: (Int, CGPoint) -> Void = { _, _ in }
    var onDragEnd: (Int, CGPoint) -> Void = { _, _ in }

    var stock: Int { store.shelves[line.id] ?? 0 }
    var capacity: Int { store.shelfCapacity }
    var fraction: Double { capacity > 0 ? Double(stock) / Double(capacity) : 0 }
    var lowStock: Bool { fraction <= 0.25 }

    var body: some View {
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
        .contentShape(Rectangle())
        // One gesture handles both: a small movement = tap (restock), a real drag onto
        // the counter = hand over a unit. minimumDistance 0 so it engages immediately and
        // wins over the surrounding scroll view; tap vs drag is decided on release.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0, coordinateSpace: .global)
                .onChanged { v in
                    if stock > 0 && (abs(v.translation.width) + abs(v.translation.height) > 6) {
                        onDragChange(line.id, v.location)
                    }
                }
                .onEnded { v in
                    let moved = abs(v.translation.width) + abs(v.translation.height)
                    if moved < 10 {
                        store.restock(line.id)              // treated as a tap
                    } else if stock > 0 {
                        onDragEnd(line.id, v.location)       // treated as a drag
                    } else {
                        onDragEnd(-1, v.location)            // clear any drag state
                    }
                }
        )
    }
}

// Grid of all stocked shelves.
struct ShelfGrid: View {
    @ObservedObject var store: MarketStore
    let columns: Int
    var onDragChange: (Int, CGPoint) -> Void = { _, _ in }
    var onDragEnd: (Int, CGPoint) -> Void = { _, _ in }

    var body: some View {
        let cols = Array(repeating: GridItem(.flexible(), spacing: 10), count: columns)
        LazyVGrid(columns: cols, spacing: 10) {
            ForEach(store.stockedLines) { line in
                ShelfTile(store: store, line: line,
                          onDragChange: onDragChange, onDragEnd: onDragEnd)
            }
        }
    }
}
