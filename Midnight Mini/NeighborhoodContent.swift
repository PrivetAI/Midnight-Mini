import SwiftUI

// MARK: - Night Modifiers (per-night events)
//
// One modifier may color a whole night, telegraphed on the start card and shown as a
// banner during the shift. Effects are bounded and never carry over between nights.

enum NightModifier: String, CaseIterable {
    case rushHour
    case rainy
    case flicker
    case friendly
    case bigDelivery
    case shoplift
    case holiday
    case quiet

    var title: String {
        switch self {
        case .rushHour:    return "Rush Hour"
        case .rainy:       return "Rainy Night"
        case .flicker:     return "Flickering Lights"
        case .friendly:    return "Friendly Night"
        case .bigDelivery: return "Big Delivery"
        case .shoplift:    return "Sticky Fingers"
        case .holiday:     return "Festival Night"
        case .quiet:       return "Quiet Night"
        }
    }

    var blurb: String {
        switch self {
        case .rushHour:    return "A crowd pours in mid-shift. Keep up!"
        case .rainy:       return "Fewer folks, but they linger and tip well."
        case .flicker:     return "The sign keeps dimming — patience runs short in the dark."
        case .friendly:    return "Everyone's in a good mood. Bigger tips all night."
        case .bigDelivery: return "The truck came early — double backroom budget."
        case .shoplift:    return "Watch the aisles — some folks try to slip out with stock."
        case .holiday:     return "The block's celebrating. Sales get a festive bump."
        case .quiet:       return "A calm night. Lower overhead, gentle pace."
        }
    }

    var accent: Color {
        switch self {
        case .rushHour:    return MarketTheme.neonAmber
        case .rainy:       return MarketTheme.neonCyan
        case .flicker:     return MarketTheme.danger
        case .friendly:    return MarketTheme.neonPink
        case .bigDelivery: return MarketTheme.neonGreen
        case .shoplift:    return MarketTheme.danger
        case .holiday:     return MarketTheme.neonViolet
        case .quiet:       return MarketTheme.textMid
        }
    }

    // Multiplier on the spawn interval (>1 = fewer customers).
    var spawnFactor: Double {
        switch self {
        case .rainy: return 1.3
        case .quiet: return 1.25
        default:     return 1.0
        }
    }

    // Multiplier on the final payment.
    var payFactor: Double {
        switch self {
        case .rainy:   return 1.25
        case .holiday: return 1.2
        default:       return 1.0
        }
    }

    // Multiplier on customer patience.
    var patienceFactor: Double {
        switch self {
        case .rainy:    return 1.2
        case .friendly: return 1.2
        default:        return 1.0
        }
    }

    // Flat additive bonus to the tip rate.
    var tipBonus: Double { self == .friendly ? 0.25 : 0.0 }

    // Multiplier on the up-front night overhead.
    var overheadFactor: Double { self == .quiet ? 0.7 : 1.0 }

    // Multiplier on the backroom budget for the night.
    var budgetFactor: Double { self == .bigDelivery ? 2.0 : 1.0 }

    var spawnsShoplifters: Bool { self == .shoplift }
    var isRush: Bool { self == .rushHour }
    var isFlicker: Bool { self == .flicker }

    // Whether this reads as a pleasant night (used for the marquee bias).
    var isGood: Bool {
        switch self {
        case .rainy, .friendly, .bigDelivery, .holiday, .quiet: return true
        default: return false
        }
    }

    // Draw a modifier for a night, or nil for the gentle opening nights (1–2).
    // The marquee upgrade biases the draw toward pleasant nights.
    static func pick(night: Int, marquee: Int) -> NightModifier? {
        guard night >= 3 else { return nil }
        var pool: [NightModifier] = []
        for m in NightModifier.allCases {
            var weight = 2
            if m.isGood { weight += marquee }                 // marquee favors good nights
            if !m.isGood && m != .rushHour { weight = max(1, 2 - marquee) } // and dampens harsh ones
            if m == .shoplift && night < 4 { weight = 0 }     // ease the shoplifter in later
            pool += Array(repeating: m, count: weight)
        }
        return pool.randomElement()
    }
}

// MARK: - Contracts (one nightly goal)

enum ContractKind {
    case serveCount
    case earnAmount
    case zeroWalkouts
    case serveRegulars
}

struct Contract: Identifiable {
    let id = UUID()
    let kind: ContractKind
    let title: String
    let target: Int
    let rewardCash: Int
    let rewardRep: Int

    // Draw a contract scaled to the night.
    static func draw(night: Int) -> Contract {
        var kinds: [ContractKind] = [.serveCount, .earnAmount, .zeroWalkouts]
        if night >= 6 { kinds.append(.serveRegulars) }
        let kind = kinds.randomElement() ?? .serveCount
        switch kind {
        case .serveCount:
            let t = 5 + night / 2
            return Contract(kind: kind, title: "Serve \(t) customers", target: t,
                            rewardCash: t * 6, rewardRep: 1)
        case .earnAmount:
            let t = 80 + night * 12
            return Contract(kind: kind, title: "Earn \(marketMoney(t)) this shift", target: t,
                            rewardCash: t / 4, rewardRep: 1)
        case .zeroWalkouts:
            return Contract(kind: kind, title: "No one walks out", target: 0,
                            rewardCash: 60 + night * 8, rewardRep: 2)
        case .serveRegulars:
            let t = 2
            return Contract(kind: kind, title: "Serve \(t) regulars", target: t,
                            rewardCash: 90, rewardRep: 2)
        }
    }
}

// MARK: - Regulars (named neighborhood characters)

struct Regular: Identifiable {
    let id: String
    let name: String
    let accent: Color
    let wantLineIds: [Int]
    let unlockNight: Int
    let unlockRep: Int
    let greeting: String
    var payFactor: Double = 1.0
    var quantityBonus: Int = 0

    static let roster: [Regular] = [
        Regular(id: "nina",   name: "Nina",      accent: MarketTheme.neonCyan,   wantLineIds: [2, 8],
                unlockNight: 3, unlockRep: 2,  greeting: "Long shift. The usual?"),
        Regular(id: "marcus", name: "Marcus",    accent: MarketTheme.neonAmber,  wantLineIds: [0, 1],
                unlockNight: 4, unlockRep: 4,  greeting: "Quick stop between fares.", payFactor: 1.1),
        Regular(id: "sal",    name: "Old Sal",   accent: MarketTheme.neonViolet, wantLineIds: [5, 9],
                unlockNight: 5, unlockRep: 6,  greeting: "Evenin'. Anything good tonight?"),
        Regular(id: "dee",    name: "Dee",       accent: MarketTheme.neonPink,   wantLineIds: [8, 3],
                unlockNight: 6, unlockRep: 9,  greeting: "Set's not over yet."),
        Regular(id: "twins",  name: "The Twins", accent: MarketTheme.neonGreen,  wantLineIds: [3, 6],
                unlockNight: 8, unlockRep: 13, greeting: "Two of everything!", quantityBonus: 2),
        Regular(id: "park",   name: "Mr. Park",  accent: MarketTheme.money,      wantLineIds: [4, 7],
                unlockNight: 10, unlockRep: 18, greeting: "Take your time, friend.", payFactor: 1.4)
    ]

    static func byId(_ id: String) -> Regular? {
        roster.first(where: { $0.id == id })
    }

    // The loyalty level at which a regular is considered a true friend.
    static let maxLoyalty: Int = 5
}

// MARK: - Story beats (cozy slice-of-life)

struct StoryBeat {
    let atNight: Int
    let text: String

    static let beats: [StoryBeat] = [
        StoryBeat(atNight: 3,  text: "Word's getting around the block: the little shop on the corner stays open when nowhere else will."),
        StoryBeat(atNight: 5,  text: "A regular leaves an extra coin in the jar 'for the late nights'. You keep it by the register."),
        StoryBeat(atNight: 7,  text: "Someone tapes a hand-drawn thank-you note to the door. You leave it up."),
        StoryBeat(atNight: 10, text: "The neighborhood's quietly chosen your counter as its midnight meeting spot."),
        StoryBeat(atNight: 12, text: "Two strangers become friends waiting in your line. Small place, big nights."),
        StoryBeat(atNight: 15, text: "The block feels a little warmer since you opened. So does the shop.")
    ]

    // The beat for a night, or nil if none.
    static func forNight(_ night: Int) -> String? {
        beats.first(where: { $0.atNight == night })?.text
    }
}

// MARK: - Achievements (lifetime goals)

struct Achievement: Identifiable {
    let id: String
    let title: String
    let detail: String
    let reward: Int
    let check: (MarketStore) -> Bool

    static let all: [Achievement] = [
        Achievement(id: "served50",   title: "Open Late",        detail: "Serve 50 customers.",            reward: 50)  { $0.lifetimeServed >= 50 },
        Achievement(id: "served250",  title: "Neighborhood Fixture", detail: "Serve 250 customers.",        reward: 150) { $0.lifetimeServed >= 250 },
        Achievement(id: "night5",     title: "Five Nights",      detail: "Reach Night 5.",                  reward: 40)  { $0.night >= 5 },
        Achievement(id: "night10",    title: "Ten Nights",       detail: "Reach Night 10.",                 reward: 100) { $0.night >= 10 },
        Achievement(id: "night20",    title: "A Real Institution", detail: "Reach Night 20.",               reward: 300) { $0.night >= 20 },
        Achievement(id: "bignight300", title: "Good Night",      detail: "Earn $300 in one night.",         reward: 80)  { $0.bestNightEarnings >= 300 },
        Achievement(id: "bignight800", title: "Record Night",    detail: "Earn $800 in one night.",         reward: 200) { $0.bestNightEarnings >= 800 },
        Achievement(id: "contracts5", title: "Reliable",         detail: "Complete 5 contracts.",           reward: 80)  { $0.contractsCompleted >= 5 },
        Achievement(id: "contracts15", title: "Dependable",      detail: "Complete 15 contracts.",          reward: 200) { $0.contractsCompleted >= 15 },
        Achievement(id: "shoplift10", title: "Eyes Open",        detail: "Catch 10 shoplifters.",           reward: 120) { $0.shopliftersCaught >= 10 },
        Achievement(id: "alllines",   title: "Fully Stocked",    detail: "Stock every product line.",       reward: 250) { $0.unlockedLines.count >= Catalog.all.count },
        Achievement(id: "friend",     title: "A Real Friend",    detail: "Max out a regular's loyalty.",    reward: 150) { s in s.regularLoyalty.values.contains(where: { $0 >= Regular.maxLoyalty }) }
    ]
}
