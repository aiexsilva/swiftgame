//
//  BossAIController.swift
//  Secrets of Time
//
//  Controla o ciclo de ataques do boss com um algoritmo de shuffle-bag:
//  todos os ataques possíveis disparam uma vez antes de qualquer repetição.
//  Três tipos de ataque: linha horizontal (pata 1×3), coluna vertical (tentáculo 3×1)
//  e célula individual (pata 1×1). Um ataque de cada vez.
//

import SpriteKit

/// Drives the boss attack loop. Uses a shuffle-bag over all 6 possible
/// attacks (3 rows + 3 columns) so the player sees full variety before
/// any attack repeats. One attack runs at a time; the next is scheduled
/// after the current one expires.
final class BossAIController {

    // MARK: - Types

    /// Todos os ataques possíveis do boss.
    private enum Attack { case row(Int), column(Int), single }

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

    /// Reconstrói e embaralha o bag com os 9 ataques possíveis:
    /// 3 linhas (pata 1×3) + 3 colunas (tentáculo 3×1) + 3 células individuais (pata 1×1).
    private func refillBag() {
        var all: [Attack] = []
        for r in 0..<gridCells.count               { all.append(.row(r)) }
        for c in 0..<(gridCells.first?.count ?? 0) { all.append(.column(c)) }
        // Três patas individuais com célula aleatória cada
        for _ in 0..<3                             { all.append(.single) }
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
            // Linha horizontal de patas 1×3 — cresce da direita para a esquerda
            attack = BossAttackHitbox.makeRow(cells: gridCells[r],
                                              cellSize: cellSize, onExpire: onExpire)
        case .column(let c):
            // Coluna vertical de tentáculos 3×1 — cresce de baixo para cima
            let col = gridCells.map { $0[c] }
            attack = BossAttackHitbox.makeColumn(cells: col,
                                                 cellSize: cellSize, onExpire: onExpire)
        case .single:
            // Pata individual 1×1 — célula aleatória da grelha
            let r = Int.random(in: 0..<gridCells.count)
            let c = Int.random(in: 0..<(gridCells.first?.count ?? 1))
            attack = BossAttackHitbox.makeSingle(cell: gridCells[r][c],
                                                 cellSize: cellSize, onExpire: onExpire)
        }
        scene.addChild(attack)
    }
}
