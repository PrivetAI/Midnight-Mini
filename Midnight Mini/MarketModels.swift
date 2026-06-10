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
        ProductLine(id: 4, name: "Sandwich",   glyph: .sandwich,  color: MarketTheme.neonGreen,  basePrice: 18, restockCost: 7,  unlockNight: 2),
        ProductLine(id: 5, name: "Magazine",   glyph: .magazine,  color: MarketTheme.neonAmber,  basePrice: 15, restockCost: 5,  unlockNight: 3),
        ProductLine(id: 6, name: "Ice Cream",  glyph: .iceCream,  color: MarketTheme.neonPink,   basePrice: 22, restockCost: 8,  unlockNight: 3),
        ProductLine(id: 7, name: "Batteries",  glyph: .batteries, color: MarketTheme.neonCyan,   basePrice: 25, restockCost: 9,  unlockNight: 4),
        ProductLine(id: 8, name: "Energy",     glyph: .energy,    color: MarketTheme.neonGreen,  basePrice: 30, restockCost: 11, unlockNight: 4),
        ProductLine(id: 9, name: "Lotto",      glyph: .lottery,   color: MarketTheme.neonViolet, basePrice: 40, restockCost: 14, unlockNight: 5),
        ProductLine(id: 10, name: "Hot Dog",    glyph: .hotDog,    color: MarketTheme.neonAmber,  basePrice: 16, restockCost: 6,  unlockNight: 5),
        ProductLine(id: 11, name: "Slushie",    glyph: .slushie,   color: MarketTheme.neonCyan,   basePrice: 14, restockCost: 5,  unlockNight: 6),
        ProductLine(id: 12, name: "Flowers",    glyph: .flowers,   color: MarketTheme.neonPink,   basePrice: 28, restockCost: 10, unlockNight: 6),
        ProductLine(id: 13, name: "Charger",    glyph: .charger,   color: MarketTheme.neonGreen,  basePrice: 35, restockCost: 13, unlockNight: 7),
        ProductLine(id: 14, name: "Plushie",    glyph: .plushie,   color: MarketTheme.neonViolet, basePrice: 45, restockCost: 16, unlockNight: 7),
        ProductLine(id: 15, name: "Water",      glyph: .water,     color: MarketTheme.neonCyan,   basePrice: 8,  restockCost: 3,  unlockNight: 8),
        ProductLine(id: 16, name: "Donut",      glyph: .donut,     color: MarketTheme.neonAmber,  basePrice: 12, restockCost: 4,  unlockNight: 8),
        ProductLine(id: 17, name: "Gum",        glyph: .gum,       color: MarketTheme.neonPink,   basePrice: 6,  restockCost: 2,  unlockNight: 9),
        ProductLine(id: 18, name: "Newspaper",  glyph: .newspaper, color: MarketTheme.neonViolet, basePrice: 10, restockCost: 3,  unlockNight: 9),
        ProductLine(id: 19, name: "Umbrella",   glyph: .umbrella,  color: MarketTheme.neonGreen,  basePrice: 26, restockCost: 9,  unlockNight: 10)
    ]

    static func line(_ id: Int) -> ProductLine {
        all.first(where: { $0.id == id }) ?? all[0]
    }
}

// MARK: - Customer quirks

enum CustomerQuirk: String, CaseIterable {
    case ordinary       // ordinary shopper
    case impatient      // patience drains faster, but pays a small rush bonus
    case bigSpender     // buys more units, pays much more, tips well
    case browser        // takes a moment before deciding (delayed arrival of order)
    case nightOwl       // happy & generous, big tip if served fast
    case haggler        // pays slightly less than list
    case tourist        // patient and generous, takes a beat to decide
    case kid            // quick, small order, modest pay
    case hoarder        // buys a big stack at once
    case regular        // a named neighborhood regular (see Regular roster)
    case shoplifter     // not a buyer — slips out with stock unless stopped

    var title: String {
        switch self {
        case .ordinary:   return "Regular"
        case .impatient:  return "Impatient"
        case .bigSpender: return "Big Spender"
        case .browser:    return "Browser"
        case .nightOwl:   return "Night Owl"
        case .haggler:    return "Haggler"
        case .tourist:    return "Tourist"
        case .kid:        return "Kid"
        case .hoarder:    return "Hoarder"
        case .regular:    return "Regular"
        case .shoplifter: return "Shoplifter"
        }
    }

    var accent: Color {
        switch self {
        case .ordinary:   return MarketTheme.textMid
        case .impatient:  return MarketTheme.danger
        case .bigSpender: return MarketTheme.neonAmber
        case .browser:    return MarketTheme.neonCyan
        case .nightOwl:   return MarketTheme.neonViolet
        case .haggler:    return MarketTheme.neonGreen
        case .tourist:    return MarketTheme.neonCyan
        case .kid:        return MarketTheme.neonGreen
        case .hoarder:    return MarketTheme.neonAmber
        case .regular:    return MarketTheme.neonPink
        case .shoplifter: return MarketTheme.danger
        }
    }

    // Multiplier on patience duration.
    var patienceFactor: Double {
        switch self {
        case .impatient: return 0.6
        case .nightOwl:  return 1.2
        case .browser:   return 1.1
        case .tourist:   return 1.3
        case .kid:       return 0.8
        case .regular:   return 1.15
        default:         return 1.0
        }
    }

    // Multiplier on payment.
    var payFactor: Double {
        switch self {
        case .bigSpender: return 1.6
        case .haggler:    return 0.85
        case .nightOwl:   return 1.15
        case .tourist:    return 1.4
        case .kid:        return 0.7
        case .regular:    return 1.1
        case .shoplifter: return 0.0
        default:          return 1.0
        }
    }

    // Quantity of units requested (before clamping to availability).
    var quantityBonus: Int {
        switch self {
        case .bigSpender: return 2
        case .hoarder:    return 3
        default:          return 0
        }
    }

    // Special customers are not ordinary buyers (resolved with bespoke logic).
    var isSpecial: Bool {
        self == .regular || self == .shoplifter
    }
}

// MARK: - Order (one line of a customer's shopping order)

struct OrderLine: Identifiable {
    let id = UUID()
    let lineId: Int
    let qty: Int
    var filled: Int = 0

    var isDone: Bool { filled >= qty }
    var remaining: Int { max(0, qty - filled) }
}

// MARK: - Customer (in-shift runtime model)

final class MarketCustomer: Identifiable, ObservableObject {
    let id = UUID()
    let quirk: CustomerQuirk
    let patienceMax: Double      // seconds of patience
    let regularId: String?       // set when this customer is a named regular
    @Published var order: [OrderLine]   // the products this customer wants
    @Published var patience: Double
    @Published var ready: Bool   // browser becomes ready after a short delay
    var browseDelay: Double      // remaining delay before the order is revealed

    init(quirk: CustomerQuirk, order: [OrderLine], patienceMax: Double, browseDelay: Double, regularId: String? = nil) {
        self.quirk = quirk
        self.order = order
        self.patienceMax = patienceMax
        self.regularId = regularId
        self.patience = patienceMax
        self.browseDelay = browseDelay
        self.ready = browseDelay <= 0
    }

    // The display name for the card (regular's name when applicable).
    var displayName: String {
        if let rid = regularId, let r = Regular.byId(rid) { return r.name }
        return quirk.title
    }

    // The whole order is fulfilled (a shoplifter has an empty order, but is never
    // resolved through this path).
    var isComplete: Bool { !order.isEmpty && order.allSatisfy { $0.isDone } }

    var totalUnits: Int { order.reduce(0) { $0 + $1.qty } }

    // A representative line id for tinting/fallback display.
    var primaryLineId: Int { order.first?.lineId ?? 0 }

    // How many more units of a given line this customer still needs.
    func remaining(_ lineId: Int) -> Int {
        order.filter { $0.lineId == lineId }.reduce(0) { $0 + $1.remaining }
    }

    // Fill one unit of the first unfinished line matching this product.
    @discardableResult
    func fill(_ lineId: Int) -> Bool {
        if let idx = order.firstIndex(where: { $0.lineId == lineId && !$0.isDone }) {
            order[idx].filled += 1
            return true
        }
        return false
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
    case camera          // reduces shoplifting losses, adds catch chance
    case loyalty         // bigger tips; regulars drop by more often
    case marquee         // brighter sign: better night events & more regulars

    var title: String {
        switch self {
        case .shelfSlots:    return "Shelf Capacity"
        case .checkoutSpeed: return "Fast Checkout"
        case .decor:         return "Neon Decor"
        case .backroom:      return "Backroom Pallets"
        case .clerk:         return "Night Clerk"
        case .camera:        return "Security Camera"
        case .loyalty:       return "Loyalty Cards"
        case .marquee:       return "Marquee Sign"
        }
    }

    var detail: String {
        switch self {
        case .shelfSlots:    return "+4 max units on every shelf."
        case .checkoutSpeed: return "Serve faster and earn a bigger tip window."
        case .decor:         return "Brighter signage pulls in customers sooner."
        case .backroom:      return "Restock more units with each tap."
        case .clerk:         return "A clerk auto-serves the front customer."
        case .camera:        return "Catch shoplifters and lose less stock."
        case .loyalty:       return "Better tips; regulars visit more often."
        case .marquee:       return "Kinder nights and more familiar faces."
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
            case .camera:        CameraIcon(size: 24, color: MarketTheme.neonCyan)
            case .loyalty:       LoyaltyIcon(size: 24, color: MarketTheme.neonPink)
            case .marquee:       MarqueeIcon(size: 24, color: MarketTheme.neonAmber)
            }
        }
    }

    var maxLevel: Int {
        switch self {
        case .clerk:   return 5
        case .camera:  return 5
        case .loyalty: return 6
        case .marquee: return 5
        default:       return 8
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
        case .camera:        base = 150
        case .loyalty:       base = 120
        case .marquee:       base = 200
        }
        return Int(base * pow(1.7, Double(level)))
    }
}
