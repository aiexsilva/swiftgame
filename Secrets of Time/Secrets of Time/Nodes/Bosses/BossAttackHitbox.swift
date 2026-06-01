import SpriteKit

enum BossAttackKind {
    case horizontal   // 3 cells in a row
    case vertical     // 3 cells in a column
    case single       // 1 cell
}

/// Container node for a boss attack telegraph → active hitbox sequence.
/// Add the returned node to the scene; it self-destructs at the end.
final class BossAttackHitbox: SKNode {

    let kind: BossAttackKind
    /// Tuning. Adjust to make attacks feel faster/slower.
    static let telegraphPerCell: TimeInterval = 0.18
    static let telegraphTail: TimeInterval = 0.36
    static let activeDuration: TimeInterval = 0.3

    private init(kind: BossAttackKind) {
        self.kind = kind
        super.init()
        zPosition = 50
        name = "bossAttack"
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Factories

    /// Horizontal row of 3 cells. `cells` should be left→right; the sweep is
    /// applied right→left so the warning reads as coming from the boss side.
    static func makeRow(cells: [CGPoint], cellSize: CGSize,
                        onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .horizontal)
        let order = Array(cells.reversed())   // right→left sweep
        node.runSequence(orderedCells: order, allCells: cells,
                         cellSize: cellSize, onExpire: onExpire)
        return node
    }

    /// Vertical column of 3 cells. `cells` should be bottom→top; the sweep is
    /// applied top→bottom.
    static func makeColumn(cells: [CGPoint], cellSize: CGSize,
                           onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .vertical)
        let order = Array(cells.reversed())   // top→bottom sweep (cells were bottom→top)
        node.runSequence(orderedCells: order, allCells: cells,
                         cellSize: cellSize, onExpire: onExpire)
        return node
    }

    /// Single cell attack — no sweep, just a quick warning pulse then activate.
    static func makeSingle(cell: CGPoint, cellSize: CGSize,
                           onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .single)
        let warning = node.makeWarning(at: cell, size: cellSize)
        node.addChild(warning)
        let totalTelegraph = telegraphPerCell * 3 + telegraphTail
        warning.run(.sequence([
            .wait(forDuration: totalTelegraph),
            .run { [weak node] in
                node?.activateAll(cells: [cell], cellSize: cellSize, onExpire: onExpire)
            },
            .removeFromParent()
        ]))
        return node
    }

    // MARK: - Internals

    /// Adds warnings in `orderedCells` order (sweep), keeps them visible,
    /// then activates ALL `allCells` simultaneously after the telegraph tail.
    private func runSequence(orderedCells: [CGPoint], allCells: [CGPoint],
                             cellSize: CGSize, onExpire: (() -> Void)?) {
        var warnings: [SKSpriteNode] = []
        for (i, cell) in orderedCells.enumerated() {
            let w = makeWarning(at: cell, size: cellSize)
            w.alpha = 0
            addChild(w)
            warnings.append(w)
            w.run(.sequence([
                .wait(forDuration: BossAttackHitbox.telegraphPerCell * Double(i)),
                .fadeIn(withDuration: 0.06)
            ]))
        }
        let totalTelegraph = BossAttackHitbox.telegraphPerCell * Double(orderedCells.count)
            + BossAttackHitbox.telegraphTail
        run(.sequence([
            .wait(forDuration: totalTelegraph),
            .run { [weak self] in
                self?.activateAll(cells: allCells, cellSize: cellSize, onExpire: onExpire)
                warnings.forEach { $0.removeFromParent() }
            }
        ]))
    }

    private func makeWarning(at point: CGPoint, size: CGSize) -> SKSpriteNode {
        let n = SKSpriteNode(color: SKColor.red.withAlphaComponent(0.35), size: size)
        n.position = point
        n.zPosition = -1
        n.run(.repeatForever(.sequence([
            .scale(to: 1.08, duration: 0.18),
            .scale(to: 1.0, duration: 0.18)
        ])))
        return n
    }

    /// Creates the live hitboxes (one per cell) with physics, holds them for
    /// `activeDuration`, then despawns the entire BossAttackHitbox.
    private func activateAll(cells: [CGPoint], cellSize: CGSize,
                             onExpire: (() -> Void)?) {
        for cell in cells {
            let live = SKSpriteNode(color: SKColor.red.withAlphaComponent(0.8), size: cellSize)
            live.position = cell
            let body = SKPhysicsBody(rectangleOf: cellSize)
            body.isDynamic = false
            body.affectedByGravity = false
            body.allowsRotation = false
            body.categoryBitMask = PhysicsCategory.bossAttack
            body.collisionBitMask = 0
            body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
            live.physicsBody = body
            live.name = "bossAttackLive"
            addChild(live)
        }
        run(.sequence([
            .wait(forDuration: BossAttackHitbox.activeDuration),
            .run { onExpire?() },
            .removeFromParent()
        ]))
    }
}
