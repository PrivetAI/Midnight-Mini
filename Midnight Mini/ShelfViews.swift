import SwiftUI

// A single compact product shelf block: tap to restock, drag the glyph up onto the
// counter to hand over a unit. Sized to fill its grid cell.
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
        VStack(spacing: 3) {
            ZStack {
                ProductGlyphView(glyph: line.glyph, size: 30,
                                 color: stock > 0 ? line.color : line.color.opacity(0.3))
                if stock == 0 {
                    Text("OUT")
                        .font(.system(size: 9, weight: .heavy, design: .rounded))
                        .foregroundColor(MarketTheme.danger)
                        .padding(.horizontal, 5).padding(.vertical, 1)
                        .background(Capsule().fill(MarketTheme.danger.opacity(0.18)))
                        .offset(y: 14)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(line.name)
                .font(.system(size: 9, weight: .bold, design: .rounded))
                .foregroundColor(MarketTheme.textHi)
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            HStack(spacing: 3) {
                ThinBar(fraction: fraction,
                        color: lowStock ? MarketTheme.danger : line.color,
                        height: 4)
                Text("\(stock)")
                    .font(.system(size: 9, weight: .heavy, design: .rounded))
                    .foregroundColor(lowStock ? MarketTheme.danger : MarketTheme.textMid)
                    .frame(width: 16, alignment: .trailing)
            }
        }
        .padding(6)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 14, style: .continuous).fill(MarketTheme.panel)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(lowStock ? MarketTheme.danger.opacity(0.7) : MarketTheme.stroke.opacity(0.5),
                        lineWidth: lowStock ? 1.5 : 1)
        )
        .contentShape(Rectangle())
        // One gesture: small movement = tap (restock), real drag onto the counter = hand
        // over a unit. minimumDistance 0 so it engages immediately; tap vs drag on release.
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
