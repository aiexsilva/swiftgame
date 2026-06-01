import SpriteKit

/// Drives the boss attack loop: picks a random attack, telegraphs and fires
/// it. Only one attack runs at a time.
final class BossAIController {

    /// `gridCells[row][col]`, row 0 = bottom, col 0 = left.
    private let gridCells: [[CGPoint]]
    private let cellSize: CGSize
    private weak var scene: SKScene?

    /// Tuning.
    var attackCooldown: TimeInterval = 1.2
    var horizontalWeight: Double = 0.4
    var verticalWeight: Double = 0.4
    var singleWeight: Double = 0.2

    private(set) var isAttacking: Bool = false
    private var isRunning: Bool = false

    init(gridCells: [[CGPoint]], cellSize: CGSize, scene: SKScene) {
        self.gridCells = gridCells
        self.cellSize = cellSize
        self.scene = scene
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        scheduleNext()
    }

    func stop() {
        isRunning = false
    }

    // MARK: - Private

    private func scheduleNext() {
        guard isRunning else { return }
        scene?.run(.sequence([
            .wait(forDuration: attackCooldown),
            .run { [weak self] in self?.fireAttackIfIdle() }
        ]))
    }

    private func fireAttackIfIdle() {
        guard isRunning, !isAttacking, let scene = scene else { return }
        isAttacking = true
        let attack = pickAttack()
        scene.addChild(attack)
    }

    private func pickAttack() -> BossAttackHitbox {
        let kind = weightedPick()
        let onExpire: () -> Void = { [weak self] in
            self?.isAttacking = false
            self?.scheduleNext()
        }
        switch kind {
        case .horizontal:
            let row = Int.random(in: 0..<gridCells.count)
            return BossAttackHitbox.makeRow(
                cells: gridCells[row],
                cellSize: cellSize,
                onExpire: onExpire
            )
        case .vertical:
            let col = Int.random(in: 0..<gridCells[0].count)
            // gridCells indexed [row][col]; row 0 is bottom → bottom→top order.
            let column = gridCells.map { $0[col] }
            return BossAttackHitbox.makeColumn(
                cells: column,
                cellSize: cellSize,
                onExpire: onExpire
            )
        case .single:
            let row = Int.random(in: 0..<gridCells.count)
            let col = Int.random(in: 0..<gridCells[0].count)
            return BossAttackHitbox.makeSingle(
                cell: gridCells[row][col],
                cellSize: cellSize,
                onExpire: onExpire
            )
        }
    }

    private func weightedPick() -> BossAttackKind {
        let total = horizontalWeight + verticalWeight + singleWeight
        let r = Double.random(in: 0..<total)
        if r < horizontalWeight { return .horizontal }
        if r < horizontalWeight + verticalWeight { return .vertical }
        return .single
    }
}
