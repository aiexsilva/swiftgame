//
//  BossAIController.swift
//  Secrets of Time
//
//  Controls the boss attack cycle using a shuffle-bag algorithm to ensure
//  every possible attack fires once before any repeats. The boss has two
//  attack types: horizontal rows (pata) and vertical columns (tentáculo).
//

import SpriteKit

/// Drives the boss attack loop. Uses a shuffle-bag over all 6 possible
/// attacks (3 rows + 3 columns) so the player sees full variety before
/// any attack repeats. One attack runs at a time; the next is scheduled
/// after the current one expires.
final class BossAIController {

    // MARK: - Types

    /// All possible attacks the boss can choose from.
    private enum Attack { case row(Int), column(Int) }

    // MARK: - Properties

    /// `gridCells[row][col]`, row 0 = bottom row, col 0 = left column.
    private let gridCells: [[CGPoint]]
    private let cellSize: CGSize
    private weak var scene: SKScene?

    /// Seconds between the end of one attack and the start of the next.
    var attackCooldown: TimeInterval = 1.4

    private(set) var isAttacking: Bool = false
    private var isRunning: Bool = false

    /// Remaining attacks in the current shuffle. Refilled and reshuffled when empty.
    private var bag: [Attack] = []

    // MARK: - Init

    init(gridCells: [[CGPoint]], cellSize: CGSize, scene: SKScene) {
        self.gridCells = gridCells
        self.cellSize  = cellSize
        self.scene     = scene
    }

    // MARK: - Control

    /// Begins the attack loop. Safe to call multiple times (idempotent).
    func start() {
        guard !isRunning else { return }
        isRunning = true
        refillBag()
        scheduleNext()
    }

    /// Stops the attack loop. Any in-progress attack will still complete.
    func stop() { isRunning = false }

    // MARK: - Private helpers

    /// Rebuilds and shuffles the bag with all 6 attacks (3 rows + 3 cols).
    private func refillBag() {
        var all: [Attack] = []
        for r in 0..<gridCells.count                    { all.append(.row(r)) }
        for c in 0..<(gridCells.first?.count ?? 0)      { all.append(.column(c)) }
        bag = all.shuffled()
    }

    /// Waits `attackCooldown` seconds then fires the next attack.
    private func scheduleNext() {
        guard isRunning else { return }
        scene?.run(.sequence([
            .wait(forDuration: attackCooldown),
            .run { [weak self] in self?.fireIfIdle() }
        ]))
    }

    /// Picks the next attack from the bag, creates the hitbox, and adds it to the scene.
    private func fireIfIdle() {
        guard isRunning, !isAttacking, let scene = scene else { return }
        isAttacking = true

        if bag.isEmpty { refillBag() }
        let next = bag.removeFirst()

        // Callback that fires when the attack hitbox expires (triggers next cycle)
        let onExpire: () -> Void = { [weak self] in
            self?.isAttacking = false
            self?.scheduleNext()
        }

        let attack: BossAttackHitbox
        switch next {
        case .row(let r):
            // Horizontal row of patas — grows right-to-left from the boss side
            attack = BossAttackHitbox.makeRow(cells: gridCells[r],
                                              cellSize: cellSize, onExpire: onExpire)
        case .column(let c):
            // Vertical column of tentáculos — grows bottom-to-top
            let col = gridCells.map { $0[c] }
            attack = BossAttackHitbox.makeColumn(cells: col,
                                                 cellSize: cellSize, onExpire: onExpire)
        }
        scene.addChild(attack)
    }
}
