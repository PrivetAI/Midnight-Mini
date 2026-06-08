import SwiftUI

// MARK: - Products

struct ProductLine: Identifiable, Equatable {
    let id: Int
    let name: String
    let glyph: ProductGlyph
    let color: Color
    let basePrice: Int        // sale price per unit to a customer
    let restockCost: Int      // backroom cost to restock one unit
    let unlockNight: Int      // night at which this line becomes purchasable as upgrade

    static func == (lhs: ProductLine, rhs: ProductLine) -> Bool { lhs.id == rhs.id }
}

enum Catalog {
    // Ordered roughly by when they unlock. id is stable and used for persistence.
    static let all: [ProductLine] = [
        ProductLine(id: 0, name: "Soda",       glyph: .bottle,    color: MarketTheme.neonCyan,   basePrice: 6,  restockCost: 2,  unlockNight: 1),
        ProductLine(id: 1, name: "Chips",      glyph: .snack,     color: MarketTheme.neonAmber,  basePrice: 8,  restockCost: 3,  unlockNight: 1),
        ProductLine(id: 2, name: "Coffee",     glyph: .coffee,    color: MarketTheme.neonViolet, basePrice: 12, restockCost: 4,  unlockNight: 1),
        ProductLine(id: 3, name: "Candy",      glyph: .candy,     color: MarketTheme.neonPink,   basePrice: 5,  restockCost: 2,  unlockNight: 2),
        ProductLine(id: 4, name: "Sandwich",   glyph: .sandwich,  color: MarketTheme.neonGreen,  basePrice: 18, restockCost: 7,  unlockNight: 3),
        ProductLine(id: 5, name: "Magazine",   glyph: .magazine,  color: MarketTheme.neonAmber,  basePrice: 15, restockCost: 5,  unlockNight: 4),
        ProductLine(id: 6, name: "Ice Cream",  glyph: .iceCream,  color: MarketTheme.neonPink,   basePrice: 22, restockCost: 8,  unlockNight: 5),
        ProductLine(id: 7, name: "Batteries",  glyph: .batteries, color: MarketTheme.neonCyan,   basePrice: 25, restockCost: 9,  unlockNight: 6),
        ProductLine(id: 8, name: "Energy",     glyph: .energy,    color: MarketTheme.neonGreen,  basePrice: 30, restockCost: 11, unlockNight: 7),
        ProductLine(id: 9, name: "Lotto",      glyph: .lottery,   color: MarketTheme.neonViolet, basePrice: 40, restockCost: 14, unlockNight: 8)
    ]

    static func line(_ id: Int) -> ProductLine {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

// MARK: - Customer quirks

enum CustomerQuirk: String, CaseIterable {
    case regular        // ordinary shopper
    case impatient      // patience drains faster, but pays a small rush bonus
    case bigSpender     // buys more units, pays much more, tips well
    case browser        // takes a moment before deciding (delayed arrival of order)
    case nightOwl       // happy & generous, big tip if served fast
    case haggler        // pays slightly less than list

    var title: String {
        switch self {
        case .regular:    return "Regular"
        case .impatient:  return "Impatient"
        case .bigSpender: return "Big Spender"
        case .browser:    return "Browser"
        case .nightOwl:   return "Night Owl"
        case .haggler:    return "Haggler"
        }
    }

    var accent: Color {
        switch self {
        case .regular:    return MarketTheme.textMid
        case .impatient:  return MarketTheme.danger
        case .bigSpender: return MarketTheme.neonAmber
        case .browser:    return MarketTheme.neonCyan
        case .nightOwl:   return MarketTheme.neonViolet
        case .haggler:    return MarketTheme.neonGreen
        }
    }

    // Multiplier on patience duration.
    var patienceFactor: Double {
        switch self {
        case .impatient: return 0.6
        case .nightOwl:  return 1.2
        case .browser:   return 1.1
        default:         return 1.0
        }
    }

    // Multiplier on payment.
    var payFactor: Double {
        switch self {
        case .bigSpender: return 1.6
        case .haggler:    return 0.85
        case .nightOwl:   return 1.15
        default:          return 1.0
        }
    }

    // Quantity of units requested (before clamping to availability).
    var quantityBonus: Int {
        switch self {
        case .bigSpender: return 2
        default:          return 0
        }
    }
}

// MARK: - Customer (in-shift runtime model)

final class MarketCustomer: Identifiable, ObservableObject {
    let id = UUID()
    let quirk: CustomerQuirk
    let wantLineId: Int
    let quantity: Int
    let patienceMax: Double      // seconds of patience
    @Published var patience: Double
    @Published var ready: Bool   // browser becomes ready after a short delay
    var browseDelay: Double      // remaining delay before the order is revealed

    init(quirk: CustomerQuirk, wantLineId: Int, quantity: Int, patienceMax: Double, browseDelay: Double) {
        self.quirk = quirk
        self.wantLineId = wantLineId
        self.quantity = quantity
        self.patienceMax = patienceMax
        self.patience = patienceMax
        self.browseDelay = browseDelay
        self.ready = browseDelay <= 0
    }

    var patienceFraction: Double {
        guard patienceMax > 0 else { return 0 }
        return max(0, min(1, patience / patienceMax))
    }
}

// MARK: - Upgrades

enum UpgradeKind: String, CaseIterable {
    case shelfSlots      // more shelf capacity per product
    case checkoutSpeed   // faster serve (reduces serve cost / adds tip window)
    case decor           // draws more customers (faster arrivals)
    case backroom        // larger restock batch per tap
    case clerk           // auto-serves the front customer periodically

    var title: String {
        switch self {
        case .shelfSlots:    return "Shelf Capacity"
        case .checkoutSpeed: return "Fast Checkout"
        case .decor:         return "Neon Decor"
        case .backroom:      return "Backroom Pallets"
        case .clerk:         return "Night Clerk"
        }
    }

    var detail: String {
        switch self {
        case .shelfSlots:    return "+4 max units on every shelf."
        case .checkoutSpeed: return "Serve faster and earn a bigger tip window."
        case .decor:         return "Brighter signage pulls in customers sooner."
        case .backroom:      return "Restock more units with each tap."
        case .clerk:         return "A clerk auto-serves the front customer."
        }
    }

    var icon: some View {
        Group {
            switch self {
            case .shelfSlots:    UpgradeIcon(size: 24, color: MarketTheme.neonCyan)
            case .checkoutSpeed: ClockIcon(size: 24, color: MarketTheme.neonAmber)
            case .decor:         StoreMarkIcon(size: 24, color: MarketTheme.neonPink)
            case .backroom:      CrateIcon(size: 24, color: MarketTheme.neonGreen)
            case .clerk:         PersonIcon(size: 24, color: MarketTheme.neonViolet)
            }
        }
    }

    var maxLevel: Int {
        switch self {
        case .clerk: return 5
        default:     return 8
        }
    }

    func cost(atLevel level: Int) -> Int {
        let base: Double
        switch self {
        case .shelfSlots:    base = 60
        case .checkoutSpeed: base = 90
        case .decor:         base = 80
        case .backroom:      base = 70
        case .clerk:         base = 180
        }
        return Int(base * pow(1.7, Double(level)))
    }
}
