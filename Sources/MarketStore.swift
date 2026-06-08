import SwiftUI
import Combine

// Game phases.
enum GamePhase {
    case storefront   // between shifts; review / upgrade / start next shift
    case shift        // a night shift is running
    case tally        // end-of-shift results overlay
}

final class MarketStore: ObservableObject {

    // MARK: - Persisted progression
    @Published var money: Int = 120
    @Published var night: Int = 1
    @Published var upgradeLevels: [String: Int] = [:]      // UpgradeKind.rawValue -> level
    @Published var unlockedLines: Set<Int> = [0, 1, 2]     // product line ids stocked in store
    @Published var bestNightEarnings: Int = 0
    @Published var lifetimeServed: Int = 0
    @Published var lifetimeEarned: Int = 0

    // MARK: - Runtime (not persisted)
    @Published var phase: GamePhase = .storefront
    @Published var shelves: [Int: Int] = [:]               // line id -> current units on shelf
    @Published var queue: [MarketCustomer] = []
    @Published var timeLeft: Double = 0
    @Published var shiftLength: Double = 60
    @Published var shiftEarnings: Int = 0
    @Published var shiftServed: Int = 0
    @Published var shiftMissed: Int = 0
    @Published var lastTally: ShiftTally? = nil
    @Published var floatingEvents: [FloatingEvent] = []

    // Backroom budget available during a shift for restocking (separate from money).
    @Published var backroomBudget: Int = 0

    private var timer: AnyCancellable?
    private var spawnAccumulator: Double = 0
    private var clerkAccumulator: Double = 0
    private let tick: Double = 1.0 / 30.0

    private let defaults = UserDefaults.standard
    private let kMoney = "nsm_money"
    private let kNight = "nsm_night"
    private let kUpg = "nsm_upgrades"
    private let kLines = "nsm_lines"
    private let kBest = "nsm_best"
    private let kServed = "nsm_served"
    private let kEarned = "nsm_earned"
    private let kHasSave = "nsm_hassave"

    init() {
        load()
    }

    // MARK: - Derived upgrade values

    func level(_ kind: UpgradeKind) -> Int { upgradeLevels[kind.rawValue] ?? 0 }

    var shelfCapacity: Int { 6 + level(.shelfSlots) * 4 }
    var restockPerTap: Int { 2 + level(.backroom) }
    // Serve cost: how much patience-time a manual serve effectively "costs" (lower is better).
    var serveTipFactor: Double { 1.0 + Double(level(.checkoutSpeed)) * 0.12 }
    // Decor reduces the spawn interval (more customers).
    var spawnInterval: Double { max(1.4, 4.2 - Double(level(.decor)) * 0.32) }
    var clerkLevel: Int { level(.clerk) }
    var hasClerk: Bool { clerkLevel > 0 }
    // Clerk auto-serve interval shrinks with level.
    var clerkInterval: Double { max(2.0, 6.0 - Double(clerkLevel) * 0.8) }

    // Cost paid at the start of each night (overhead that ramps with difficulty).
    var nightOverhead: Int { 30 + (night - 1) * 18 }

    // MARK: - Storefront helpers

    var availableUpgrades: [UpgradeKind] { UpgradeKind.allCases }

    func upgradeCost(_ kind: UpgradeKind) -> Int? {
        let lvl = level(kind)
        if lvl >= kind.maxLevel { return nil }
        return kind.cost(atLevel: lvl)
    }

    func canBuy(_ kind: UpgradeKind) -> Bool {
        guard let c = upgradeCost(kind) else { return false }
        return money >= c
    }

    func buy(_ kind: UpgradeKind) {
        guard let c = upgradeCost(kind), money >= c else { return }
        money -= c
        upgradeLevels[kind.rawValue] = level(kind) + 1
        save()
    }

    // New product lines unlockable this night.
    var lockedLinesForSale: [ProductLine] {
        Catalog.all.filter { !unlockedLines.contains($0.id) && $0.unlockNight <= night }
    }

    func lineUnlockCost(_ line: ProductLine) -> Int {
        // Cost scales with the line's value.
        max(40, line.basePrice * 12)
    }

    func unlockLine(_ line: ProductLine) {
        let cost = lineUnlockCost(line)
        guard !unlockedLines.contains(line.id), money >= cost else { return }
        money -= cost
        unlockedLines.insert(line.id)
        save()
    }

    var stockedLines: [ProductLine] {
        Catalog.all.filter { unlockedLines.contains($0.id) }
    }

    // MARK: - Shift lifecycle

    func startShift() {
        // Pay overhead up front.
        money = max(0, money - nightOverhead)
        // Backroom budget for the night: a fraction of cash, plus a base.
        backroomBudget = 60 + night * 20
        // Fill shelves to capacity for stocked lines.
        shelves = [:]
        for line in stockedLines { shelves[line.id] = shelfCapacity }
        queue = []
        timeLeft = shiftLength
        shiftEarnings = 0
        shiftServed = 0
        shiftMissed = 0
        spawnAccumulator = 1.0
        clerkAccumulator = 0
        floatingEvents = []
        phase = .shift
        save()
        startTimer()
    }

    private func startTimer() {
        timer?.cancel()
        timer = Timer.publish(every: tick, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.update() }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func update() {
        guard phase == .shift else { return }
        timeLeft -= tick
        if timeLeft <= 0 {
            timeLeft = 0
            endShift()
            return
        }

        // Difficulty scales arrival pace and customer count cap over the night.
        let maxQueue = 4 + min(4, night / 2)

        // Spawn logic.
        spawnAccumulator -= tick
        if spawnAccumulator <= 0 && queue.count < maxQueue {
            spawnCustomer()
            // Faster arrivals later in the night and with more nights.
            let nightPace = max(0.6, 1.0 - Double(night) * 0.03)
            spawnAccumulator = spawnInterval * nightPace * Double.random(in: 0.8...1.25)
        }

        // Update each customer.
        var toRemove: [UUID] = []
        for c in queue {
            if !c.ready {
                c.browseDelay -= tick
                if c.browseDelay <= 0 { c.ready = true }
                continue
            }
            c.patience -= tick
            if c.patience <= 0 {
                toRemove.append(c.id)
            }
        }
        if !toRemove.isEmpty {
            for id in toRemove {
                if let c = queue.first(where: { $0.id == id }) {
                    shiftMissed += 1
                    addFloating(text: "Left!", color: MarketTheme.danger, atFront: c.id == queue.first?.id)
                }
            }
            queue.removeAll { toRemove.contains($0.id) }
        }

        // Clerk auto-serve.
        if hasClerk {
            clerkAccumulator += tick
            if clerkAccumulator >= clerkInterval {
                clerkAccumulator = 0
                autoServeFront()
            }
        }

        // Decay floating events.
        for i in floatingEvents.indices {
            floatingEvents[i].life -= tick
            floatingEvents[i].offset -= tick * 26
        }
        floatingEvents.removeAll { $0.life <= 0 }
    }

    private func spawnCustomer() {
        // Pick a quirk weighted by night (more odd customers as nights progress).
        let quirk = pickQuirk()
        // Choose a product line that's stocked.
        let lines = stockedLines
        guard let line = lines.randomElement() else { return }
        var qty = 1 + quirk.quantityBonus
        if Double.random(in: 0...1) < 0.25 { qty += 1 }
        qty = min(qty, 4)
        // Patience scales: shorter at higher nights.
        let basePatience = max(5.0, 11.0 - Double(night) * 0.4)
        let patience = basePatience * quirk.patienceFactor
        let browse = quirk == .browser ? Double.random(in: 1.5...3.0) : 0
        let c = MarketCustomer(quirk: quirk, wantLineId: line.id, quantity: qty, patienceMax: patience, browseDelay: browse)
        queue.append(c)
    }

    private func pickQuirk() -> CustomerQuirk {
        // Weighted pool; oddities grow with night.
        var pool: [CustomerQuirk] = [.regular, .regular, .regular]
        if night >= 1 { pool += [.impatient] }
        if night >= 2 { pool += [.bigSpender, .browser] }
        if night >= 3 { pool += [.nightOwl] }
        if night >= 4 { pool += [.haggler, .impatient] }
        if night >= 6 { pool += [.bigSpender, .nightOwl] }
        return pool.randomElement() ?? .regular
    }

    // MARK: - Player actions

    // Restock the given line from the backroom budget.
    func restock(_ lineId: Int) {
        guard phase == .shift else { return }
        let line = Catalog.line(lineId)
        let current = shelves[lineId] ?? 0
        let room = shelfCapacity - current
        guard room > 0 else { return }
        var units = min(restockPerTap, room)
        var cost = units * line.restockCost
        // Clamp by available budget.
        while units > 0 && cost > backroomBudget {
            units -= 1
            cost = units * line.restockCost
        }
        guard units > 0 else {
            addFloating(text: "No budget", color: MarketTheme.danger, atFront: false)
            return
        }
        backroomBudget -= cost
        shelves[lineId] = current + units
        addFloating(text: "+\(units)", color: line.color, atFront: false)
    }

    // Serve the front (first ready) customer manually.
    func serveFront() {
        guard phase == .shift else { return }
        guard let c = frontReadyCustomer() else { return }
        attemptServe(c, isAuto: false)
    }

    private func autoServeFront() {
        guard let c = frontReadyCustomer() else { return }
        attemptServe(c, isAuto: true)
    }

    func frontReadyCustomer() -> MarketCustomer? {
        queue.first(where: { $0.ready })
    }

    private func attemptServe(_ c: MarketCustomer, isAuto: Bool) {
        let line = Catalog.line(c.wantLineId)
        let available = shelves[c.wantLineId] ?? 0
        guard available > 0 else {
            if !isAuto {
                addFloating(text: "Empty shelf", color: MarketTheme.danger, atFront: true)
            }
            return
        }
        let sold = min(c.quantity, available)
        shelves[c.wantLineId] = available - sold

        // Payment.
        var pay = Double(sold * line.basePrice) * c.quirk.payFactor
        // Tip based on remaining patience and checkout speed.
        let promptness = c.patienceFraction
        let tip = Double(sold * line.basePrice) * 0.35 * promptness * serveTipFactor
        var total = Int((pay + tip).rounded())
        // Impatient customers leave a small rush bonus when served quickly.
        if c.quirk == .impatient && promptness > 0.5 { total += 4 }
        pay = Double(total)

        shiftEarnings += total
        money += total
        shiftServed += 1
        lifetimeServed += 1
        lifetimeEarned += total

        addFloating(text: marketMoney(total), color: MarketTheme.money, atFront: true)
        queue.removeAll { $0.id == c.id }
    }

    private func addFloating(text: String, color: Color, atFront: Bool) {
        let ev = FloatingEvent(text: text, color: color, anchorFront: atFront)
        floatingEvents.append(ev)
        if floatingEvents.count > 8 { floatingEvents.removeFirst() }
    }

    private func endShift() {
        stopTimer()
        let tally = ShiftTally(
            night: night,
            earnings: shiftEarnings,
            served: shiftServed,
            missed: shiftMissed,
            overhead: nightOverhead
        )
        lastTally = tally
        if shiftEarnings > bestNightEarnings { bestNightEarnings = shiftEarnings }
        queue = []
        phase = .tally
        save()
    }

    // Player taps "continue" on the tally → go back to storefront, advance night.
    func continueAfterTally() {
        night += 1
        phase = .storefront
        save()
    }

    func abandonShift() {
        // Allow leaving a shift early (counts current earnings).
        endShift()
    }

    // MARK: - Reset

    func resetProgress() {
        money = 120
        night = 1
        upgradeLevels = [:]
        unlockedLines = [0, 1, 2]
        bestNightEarnings = 0
        lifetimeServed = 0
        lifetimeEarned = 0
        phase = .storefront
        save()
    }

    // MARK: - Persistence

    func save() {
        defaults.set(money, forKey: kMoney)
        defaults.set(night, forKey: kNight)
        defaults.set(upgradeLevels, forKey: kUpg)
        defaults.set(Array(unlockedLines), forKey: kLines)
        defaults.set(bestNightEarnings, forKey: kBest)
        defaults.set(lifetimeServed, forKey: kServed)
        defaults.set(lifetimeEarned, forKey: kEarned)
        defaults.set(true, forKey: kHasSave)
    }

    private func load() {
        guard defaults.bool(forKey: kHasSave) else { return }
        money = defaults.integer(forKey: kMoney)
        night = max(1, defaults.integer(forKey: kNight))
        if let u = defaults.dictionary(forKey: kUpg) as? [String: Int] { upgradeLevels = u }
        if let l = defaults.array(forKey: kLines) as? [Int], !l.isEmpty { unlockedLines = Set(l) }
        bestNightEarnings = defaults.integer(forKey: kBest)
        lifetimeServed = defaults.integer(forKey: kServed)
        lifetimeEarned = defaults.integer(forKey: kEarned)
    }
}

// MARK: - Support types

struct ShiftTally {
    let night: Int
    let earnings: Int
    let served: Int
    let missed: Int
    let overhead: Int
}

struct FloatingEvent: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let anchorFront: Bool
    var life: Double = 1.1
    var offset: Double = 0
}
