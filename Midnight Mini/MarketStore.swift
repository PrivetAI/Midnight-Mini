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
    @Published var unlockedLines: Set<Int> = [0, 1, 2, 3]  // product line ids stocked in store
    @Published var bestNightEarnings: Int = 0
    @Published var lifetimeServed: Int = 0
    @Published var lifetimeEarned: Int = 0
    @Published var reputation: Int = 0                      // ★ earned from clean nights & contracts
    @Published var regularLoyalty: [String: Int] = [:]     // Regular.id -> loyalty level
    @Published var unlockedAchievements: Set<String> = []  // Achievement.id
    @Published var contractsCompleted: Int = 0
    @Published var shopliftersCaught: Int = 0

    // MARK: - Runtime (not persisted)
    @Published var phase: GamePhase = .storefront
    @Published var shelves: [Int: Int] = [:]               // line id -> current units on shelf
    @Published var queue: [MarketCustomer] = []
    @Published var timeLeft: Double = 0
    @Published var shiftLength: Double = 60
    @Published var shiftEarnings: Int = 0
    @Published var shiftServed: Int = 0
    @Published var shiftMissed: Int = 0
    @Published var shiftRegularsServed: Int = 0
    @Published var lastTally: ShiftTally? = nil
    @Published var floatingEvents: [FloatingEvent] = []

    // Night event + nightly contract (runtime, chosen at shift start).
    @Published var currentModifier: NightModifier? = nil
    @Published var currentContract: Contract? = nil
    @Published var contractComplete: Bool = false
    @Published var dimNow: Bool = false                    // flicker: lights are dim right now
    @Published var rushActive: Bool = false               // rush hour window is open
    @Published var pendingStoryBeat: String? = nil        // shown on the tally if set
    @Published var newlyUnlockedAchievements: [String] = []

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
    private let kRep = "nsm_rep"
    private let kLoyalty = "nsm_loyalty"
    private let kAch = "nsm_ach"
    private let kContracts = "nsm_contracts"
    private let kShoplift = "nsm_shoplift"

    init() {
        load()
        prepareNight()
    }

    // Choose tonight's event + contract so the storefront can preview them.
    func prepareNight() {
        currentModifier = NightModifier.pick(night: night, marquee: marqueeLevel)
        currentContract = Contract.draw(night: night)
        contractComplete = false
    }

    // MARK: - Derived upgrade values

    func level(_ kind: UpgradeKind) -> Int { upgradeLevels[kind.rawValue] ?? 0 }

    var shelfCapacity: Int { 6 + level(.shelfSlots) * 4 }
    var restockPerTap: Int { 2 + level(.backroom) }
    // Serve cost: how much patience-time a manual serve effectively "costs" (lower is better).
    // Loyalty Cards add a small, capped tip bonus on top of Fast Checkout.
    var serveTipFactor: Double { 1.0 + Double(level(.checkoutSpeed)) * 0.12 + Double(level(.loyalty)) * 0.06 }
    // Decor reduces the spawn interval (more customers).
    var spawnInterval: Double { max(1.4, 4.2 - Double(level(.decor)) * 0.32) }
    var clerkLevel: Int { level(.clerk) }
    var hasClerk: Bool { clerkLevel > 0 }
    // Clerk auto-serve interval shrinks with level.
    var clerkInterval: Double { max(2.0, 6.0 - Double(clerkLevel) * 0.8) }

    var marqueeLevel: Int { level(.marquee) }
    // Units a shoplifter slips out with when not stopped (Security Camera reduces this).
    var theftUnits: Int { max(1, 2 + night / 8 - level(.camera)) }
    // Chance the camera auto-catches a shoplifter as they leave.
    var cameraCatchChance: Double { Double(level(.camera)) * 0.12 }
    // Cash reward for stopping a shoplifter.
    var catchReward: Int { 8 + level(.camera) * 4 }

    // Cost paid at the start of each night (overhead that ramps with difficulty).
    var nightOverhead: Int {
        let base = 30 + (night - 1) * 18
        return Int(Double(base) * (currentModifier?.overheadFactor ?? 1.0))
    }

    // Regulars that have been unlocked by night & reputation.
    var unlockedRegulars: [Regular] {
        Regular.roster.filter { night >= $0.unlockNight && reputation >= $0.unlockRep }
    }

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
        // Cost scales with the line's value (kept affordable so the store fills out fast).
        max(30, line.basePrice * 7)
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
        // Pay overhead up front (already reflects tonight's modifier).
        money = max(0, money - nightOverhead)
        // Backroom budget for the night: a base, doubled on a Big Delivery night.
        let baseBudget = 60 + night * 20
        backroomBudget = Int(Double(baseBudget) * (currentModifier?.budgetFactor ?? 1.0))
        // Fill shelves to capacity for stocked lines.
        shelves = [:]
        for line in stockedLines { shelves[line.id] = shelfCapacity }
        queue = []
        timeLeft = shiftLength
        shiftEarnings = 0
        shiftServed = 0
        shiftMissed = 0
        shiftRegularsServed = 0
        contractComplete = false
        dimNow = false
        rushActive = false
        newlyUnlockedAchievements = []
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

    // Pause/resume the running shift (used while a confirmation prompt is open) so the
    // clock isn't ticking and the view isn't re-rendering 30×/sec behind the prompt.
    func pauseShift() {
        guard phase == .shift else { return }
        stopTimer()
    }

    func resumeShift() {
        guard phase == .shift, timer == nil else { return }
        startTimer()
    }

    private func update() {
        guard phase == .shift else { return }
        timeLeft -= tick
        if timeLeft <= 0 {
            timeLeft = 0
            endShift()
            return
        }

        // Night-event timing windows derived from elapsed time.
        let elapsed = shiftLength - timeLeft
        if let m = currentModifier, m.isRush {
            rushActive = elapsed >= 18 && elapsed <= 34
        } else {
            rushActive = false
        }
        if let m = currentModifier, m.isFlicker {
            dimNow = elapsed.truncatingRemainder(dividingBy: 4.0) < 1.4
        } else {
            dimNow = false
        }

        // Difficulty scales arrival pace and customer count cap over the night.
        let maxQueue = 4 + min(4, night / 2) + (rushActive ? 2 : 0)

        // Spawn logic.
        spawnAccumulator -= tick
        if spawnAccumulator <= 0 && queue.count < maxQueue {
            spawnCustomer()
            // Faster arrivals later in the night and with more nights.
            let nightPace = max(0.6, 1.0 - Double(night) * 0.03)
            var interval = spawnInterval * nightPace * Double.random(in: 0.8...1.25)
            interval *= (currentModifier?.spawnFactor ?? 1.0)
            if rushActive { interval *= 0.5 }
            spawnAccumulator = interval
        }

        // Patience drains faster while the lights are dim.
        let drain = dimNow ? tick * 1.6 : tick

        // Update each customer.
        var toRemove: [UUID] = []
        for c in queue {
            if !c.ready {
                c.browseDelay -= tick
                if c.browseDelay <= 0 { c.ready = true }
                continue
            }
            c.patience -= drain
            if c.patience <= 0 {
                toRemove.append(c.id)
            }
        }
        if !toRemove.isEmpty {
            for id in toRemove {
                if let c = queue.first(where: { $0.id == id }) {
                    if c.quirk == .shoplifter {
                        handleShoplifterLeaving(c)
                    } else {
                        shiftMissed += 1
                        addFloating(text: "Left!", color: MarketTheme.danger, atFront: c.id == queue.first?.id)
                    }
                }
            }
            queue.removeAll { toRemove.contains($0.id) }
        }

        // Clerk auto-serve.
        if hasClerk {
            clerkAccumulator += tick
            if clerkAccumulator >= clerkInterval {
                clerkAccumulator = 0
                autoCompleteFront()
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
        let lines = stockedLines
        guard !lines.isEmpty else { return }
        let basePatience = max(5.0, 11.0 - Double(night) * 0.4)

        // Shoplifter (only on a Sticky Fingers night) — no order, resolved by tapping.
        if let m = currentModifier, m.spawnsShoplifters, Double.random(in: 0...1) < 0.18 {
            let patience = max(4.0, 8.0 - Double(night) * 0.2)
            queue.append(MarketCustomer(quirk: .shoplifter, order: [],
                                        patienceMax: patience, browseDelay: 0))
            return
        }

        // A familiar face?
        if let reg = dueRegular(), Double.random(in: 0...1) < regularSpawnChance {
            let pref = reg.wantLineIds.filter { unlockedLines.contains($0) }
            let order = makeOrder(stocked: lines, preferred: pref, quirk: .regular)
            let patience = basePatience * CustomerQuirk.regular.patienceFactor
            queue.append(MarketCustomer(quirk: .regular, order: order,
                                        patienceMax: patience, browseDelay: 0, regularId: reg.id))
            return
        }

        // Ordinary night customer.
        let quirk = pickQuirk()
        let order = makeOrder(stocked: lines, preferred: nil, quirk: quirk)
        let patience = basePatience * quirk.patienceFactor
        let browse = quirk == .browser ? Double.random(in: 1.5...3.0) : 0
        queue.append(MarketCustomer(quirk: quirk, order: order,
                                    patienceMax: patience, browseDelay: browse))
    }

    // Build an order: a few distinct stocked lines, quantities scaled by night & quirk,
    // total units capped so it stays fulfillable in time.
    private func makeOrder(stocked: [ProductLine], preferred: [Int]?, quirk: CustomerQuirk) -> [OrderLine] {
        // How many distinct lines this order can have — grows gradually with the night.
        let maxLines = 1 + min(3, (night - 1) / 3)  // n1-3:1, 4-6:2, 7-9:3, 10+:4
        var lineCount = Int.random(in: 1...max(1, maxLines))
        if quirk == .kid { lineCount = 1 }          // kids keep it simple
        if quirk == .hoarder { lineCount = min(maxLines, lineCount + 1) }
        lineCount = min(lineCount, stocked.count)

        // Pick distinct line ids, favoring the regular's preferred lines first.
        var pool = stocked.map { $0.id }.shuffled()
        if let pref = preferred, !pref.isEmpty {
            pool = (pref.shuffled() + pool.filter { !pref.contains($0) })
        }
        let chosen = Array(pool.prefix(lineCount))

        var order: [OrderLine] = []
        var units = 0
        let unitCap = 5
        for (i, lid) in chosen.enumerated() {
            var qty = 1
            if Double.random(in: 0...1) < 0.30 { qty += 1 }
            if quirk == .hoarder { qty += 1 }
            if quirk == .bigSpender && i == 0 { qty += 1 }
            if quirk == .kid { qty = 1 }
            qty = min(qty, max(1, unitCap - units))
            if qty <= 0 { break }
            order.append(OrderLine(lineId: lid, qty: qty))
            units += qty
            if units >= unitCap { break }
        }
        if order.isEmpty, let lid = chosen.first ?? stocked.first?.id {
            order = [OrderLine(lineId: lid, qty: 1)]
        }
        return order
    }

    private func pickQuirk() -> CustomerQuirk {
        // Weighted pool; oddities grow with night.
        var pool: [CustomerQuirk] = [.ordinary, .ordinary, .ordinary]
        if night >= 1 { pool += [.impatient, .kid] }
        if night >= 2 { pool += [.bigSpender, .browser, .tourist] }
        if night >= 3 { pool += [.nightOwl] }
        if night >= 4 { pool += [.haggler, .impatient] }
        if night >= 5 { pool += [.hoarder] }
        if night >= 6 { pool += [.bigSpender, .nightOwl] }
        return pool.randomElement() ?? .ordinary
    }

    // A regular who is unlocked and not already in the queue.
    private func dueRegular() -> Regular? {
        let present = Set(queue.compactMap { $0.regularId })
        return unlockedRegulars.filter { !present.contains($0.id) }.randomElement()
    }

    private var regularSpawnChance: Double {
        min(0.32, 0.10 + Double(marqueeLevel) * 0.02 + Double(level(.loyalty)) * 0.01)
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

    func frontReadyCustomer() -> MarketCustomer? {
        queue.first(where: { $0.ready })
    }

    // Drop one unit of a product onto the front customer's order (drag-to-fill).
    func dropProduct(_ lineId: Int) {
        guard phase == .shift, let c = frontReadyCustomer() else { return }
        guard c.quirk != .shoplifter else { return }  // shoplifters are tapped, not filled
        guard c.remaining(lineId) > 0 else {
            addFloating(text: "Not needed", color: MarketTheme.danger, atFront: true)
            return
        }
        let available = shelves[lineId] ?? 0
        guard available > 0 else {
            addFloating(text: "Empty shelf", color: MarketTheme.danger, atFront: true)
            return
        }
        shelves[lineId] = available - 1
        c.fill(lineId)
        addFloating(text: "+1", color: Catalog.line(lineId).color, atFront: true)
        if c.isComplete { completeOrder(c) }
    }

    // Tap path for a shoplifter standing at the counter.
    func stopFrontShoplifter() {
        guard phase == .shift, let c = frontReadyCustomer(), c.quirk == .shoplifter else { return }
        catchShoplifter(c, viaCamera: false)
        updateContractProgress()
    }

    // Clerk auto-fills the front customer's order as far as stock allows.
    private func autoCompleteFront() {
        guard let c = frontReadyCustomer() else { return }
        if c.quirk == .shoplifter {
            catchShoplifter(c, viaCamera: true)
            updateContractProgress()
            return
        }
        for ol in c.order where !ol.isDone {
            while c.remaining(ol.lineId) > 0 && (shelves[ol.lineId] ?? 0) > 0 {
                shelves[ol.lineId]! -= 1
                c.fill(ol.lineId)
            }
        }
        if c.isComplete { completeOrder(c) }
    }

    // Pay out a finished order and clear the customer.
    private func completeOrder(_ c: MarketCustomer) {
        // Per-customer pay factor; regulars carry their own plus a small loyalty bump.
        var custPayFactor = c.quirk.payFactor
        if let rid = c.regularId, let reg = Regular.byId(rid) {
            let loyalty = min(regularLoyalty[rid] ?? 0, Regular.maxLoyalty)
            custPayFactor = reg.payFactor + Double(loyalty) * 0.03
        }
        let modPay = currentModifier?.payFactor ?? 1.0
        let tipBonus = currentModifier?.tipBonus ?? 0.0
        let promptness = c.patienceFraction

        var total = 0
        for ol in c.order {
            let line = Catalog.line(ol.lineId)
            let base = Double(ol.qty * line.basePrice)
            let pay = base * custPayFactor
            let tip = base * (0.35 + tipBonus) * promptness * serveTipFactor
            total += Int(((pay + tip) * modPay).rounded())
        }
        // Impatient customers leave a small rush bonus when served quickly.
        if c.quirk == .impatient && promptness > 0.5 { total += 4 }

        shiftEarnings += total
        money += total
        shiftServed += 1
        lifetimeServed += 1
        lifetimeEarned += total

        // Build loyalty with a returning regular.
        if let rid = c.regularId {
            shiftRegularsServed += 1
            let before = regularLoyalty[rid] ?? 0
            if before < Regular.maxLoyalty {
                let now = before + 1
                regularLoyalty[rid] = now
                if now >= Regular.maxLoyalty, let reg = Regular.byId(rid) {
                    pendingStoryBeat = "\(reg.name) is a true regular now — your place is their place."
                    reputation += 1
                }
            }
        }

        addFloating(text: marketMoney(total), color: MarketTheme.money, atFront: true)
        queue.removeAll { $0.id == c.id }
        updateContractProgress()
        checkAchievements()
    }

    private func catchShoplifter(_ c: MarketCustomer, viaCamera: Bool) {
        let reward = catchReward
        money += reward
        shiftEarnings += reward
        shopliftersCaught += 1
        addFloating(text: (viaCamera ? "Camera! " : "Caught! ") + marketMoney(reward),
                    color: MarketTheme.neonCyan, atFront: !viaCamera)
        queue.removeAll { $0.id == c.id }
        checkAchievements()
    }

    private func handleShoplifterLeaving(_ c: MarketCustomer) {
        // The camera may still catch them on the way out.
        if Double.random(in: 0...1) < cameraCatchChance {
            catchShoplifter(c, viaCamera: true)
            return
        }
        // Otherwise they slip out with some stock.
        let stocked = stockedLines.filter { (shelves[$0.id] ?? 0) > 0 }
        if let victim = stocked.randomElement() {
            let have = shelves[victim.id] ?? 0
            let taken = min(theftUnits, have)
            shelves[victim.id] = have - taken
            addFloating(text: "Stolen -\(taken)", color: MarketTheme.danger, atFront: false)
        }
    }

    private func updateContractProgress() {
        guard let c = currentContract, !contractComplete else { return }
        switch c.kind {
        case .serveCount:    if shiftServed >= c.target { contractComplete = true }
        case .earnAmount:    if shiftEarnings >= c.target { contractComplete = true }
        case .serveRegulars: if shiftRegularsServed >= c.target { contractComplete = true }
        case .zeroWalkouts:  break // resolved at end of shift
        }
    }

    func checkAchievements() {
        for a in Achievement.all where !unlockedAchievements.contains(a.id) {
            if a.check(self) {
                unlockedAchievements.insert(a.id)
                money += a.reward
                newlyUnlockedAchievements.append(a.id)
                if phase == .shift {
                    addFloating(text: "Achievement!", color: MarketTheme.neonAmber, atFront: false)
                }
            }
        }
    }

    private func addFloating(text: String, color: Color, atFront: Bool) {
        let ev = FloatingEvent(text: text, color: color, anchorFront: atFront)
        floatingEvents.append(ev)
        if floatingEvents.count > 8 { floatingEvents.removeFirst() }
    }

    private func endShift() {
        stopTimer()
        dimNow = false
        rushActive = false

        // Resolve the zero-walkout contract now that the shift is over.
        if let c = currentContract, !contractComplete, c.kind == .zeroWalkouts, shiftMissed == 0 {
            contractComplete = true
        }

        var contractReward = 0
        var repGained = 0
        if let c = currentContract, contractComplete {
            contractReward = c.rewardCash
            money += c.rewardCash
            repGained += c.rewardRep
            contractsCompleted += 1
        }
        // A clean night (no walkouts) earns a reputation point.
        if shiftMissed == 0 { repGained += 1 }
        reputation += repGained

        // Story beat for reaching this night (a loyalty-max beat may already be pending).
        if pendingStoryBeat == nil { pendingStoryBeat = StoryBeat.forNight(night) }

        let tally = ShiftTally(
            night: night,
            earnings: shiftEarnings,
            served: shiftServed,
            missed: shiftMissed,
            overhead: nightOverhead,
            contractTitle: currentContract?.title,
            contractDone: contractComplete,
            contractReward: contractReward,
            reputationGained: repGained
        )
        lastTally = tally
        if shiftEarnings > bestNightEarnings { bestNightEarnings = shiftEarnings }
        queue = []
        phase = .tally
        checkAchievements()
        save()
    }

    // Player taps "continue" on the tally → go back to storefront, advance night.
    func continueAfterTally() {
        night += 1
        pendingStoryBeat = nil
        newlyUnlockedAchievements = []
        phase = .storefront
        prepareNight()
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
        unlockedLines = [0, 1, 2, 3]
        bestNightEarnings = 0
        lifetimeServed = 0
        lifetimeEarned = 0
        reputation = 0
        regularLoyalty = [:]
        unlockedAchievements = []
        contractsCompleted = 0
        shopliftersCaught = 0
        pendingStoryBeat = nil
        newlyUnlockedAchievements = []
        phase = .storefront
        prepareNight()
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
        defaults.set(reputation, forKey: kRep)
        defaults.set(regularLoyalty, forKey: kLoyalty)
        defaults.set(Array(unlockedAchievements), forKey: kAch)
        defaults.set(contractsCompleted, forKey: kContracts)
        defaults.set(shopliftersCaught, forKey: kShoplift)
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
        // New keys are additive — older saves simply read as defaults.
        reputation = defaults.integer(forKey: kRep)
        if let lo = defaults.dictionary(forKey: kLoyalty) as? [String: Int] { regularLoyalty = lo }
        if let ac = defaults.array(forKey: kAch) as? [String] { unlockedAchievements = Set(ac) }
        contractsCompleted = defaults.integer(forKey: kContracts)
        shopliftersCaught = defaults.integer(forKey: kShoplift)
    }
}

// MARK: - Support types

struct ShiftTally {
    let night: Int
    let earnings: Int
    let served: Int
    let missed: Int
    let overhead: Int
    var contractTitle: String? = nil
    var contractDone: Bool = false
    var contractReward: Int = 0
    var reputationGained: Int = 0
}

struct FloatingEvent: Identifiable {
    let id = UUID()
    let text: String
    let color: Color
    let anchorFront: Bool
    var life: Double = 1.1
    var offset: Double = 0
}
