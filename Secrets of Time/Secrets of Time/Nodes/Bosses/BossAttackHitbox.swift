//
//  BossAttackHitbox.swift
//  Secrets of Time
//
//  Hitboxes dos dois tipos de ataque do boss:
//    • horizontal (pata)    — linha de células que cresce da direita para a esquerda
//    • vertical (tentáculo) — coluna de células que cresce de baixo para cima
//  Cada ataque exibe sinais de aviso (warning) antes de ativar a hitbox real,
//  dando ao jogador tempo para se esquivar.
//

import SpriteKit

/// Tipo de ataque do boss: horizontal (pata) ou vertical (tentáculo).
enum BossAttackKind {
    case horizontal   // linha de patas, hitbox cresce da direita para a esquerda
    case vertical     // coluna de tentáculos, hitbox cresce de baixo para cima
}

/// Telegraph (3 warning signs in separate cells) + single combined active hitbox
/// that grows from a portal placed at the attack origin edge.
final class BossAttackHitbox: SKNode {

    let kind: BossAttackKind

    static let telegraphPerCell: TimeInterval = 0.22
    static let telegraphTail:    TimeInterval = 0.35
    static let growDuration:     TimeInterval = 0.25   // time for the hitbox to fully extend
    static let holdDuration:     TimeInterval = 0.35   // time the full hitbox stays active

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

    /// Horizontal row (pata). `cells` left→right. Portal spawns on RIGHT edge.
    static func makeRow(cells: [CGPoint], cellSize: CGSize,
                        onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .horizontal)
        // Sweep warnings right→left (closest to portal first)
        let sweepOrder = Array(cells.reversed())
        // Portal appears just to the right of the rightmost cell
        let rightEdge = (cells.last?.x ?? 0) + cellSize.width / 2
        let portalPos  = CGPoint(x: rightEdge + 24, y: cells[0].y)
        node.runAttack(sweepOrder: sweepOrder, cells: cells,
                       cellSize: cellSize, portalPos: portalPos,
                       hitboxImage: "pata", horizontal: true, onExpire: onExpire)
        return node
    }

    /// Vertical column (tentáculo). `cells` bottom→top. Portal spawns on BOTTOM edge.
    static func makeColumn(cells: [CGPoint], cellSize: CGSize,
                           onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .vertical)
        // Sweep warnings bottom→top (closest to portal first)
        let sweepOrder = cells
        let bottomEdge = (cells.first?.y ?? 0) - cellSize.height / 2
        let portalPos  = CGPoint(x: cells[0].x, y: bottomEdge - 24)
        node.runAttack(sweepOrder: sweepOrder, cells: cells,
                       cellSize: cellSize, portalPos: portalPos,
                       hitboxImage: "tentaculo", horizontal: false, onExpire: onExpire)
        return node
    }

    // MARK: - Core sequence

    private func runAttack(sweepOrder: [CGPoint], cells: [CGPoint],
                           cellSize: CGSize, portalPos: CGPoint,
                           hitboxImage: String, horizontal: Bool,
                           onExpire: (() -> Void)?) {
        // 1. Portal
        let portal = makePortal(at: portalPos, size: cellSize)
        addChild(portal)

        // 2. Warning signs — one per cell in sweep order
        for (i, cell) in sweepOrder.enumerated() {
            let w = makeWarning(at: cell, size: cellSize)
            w.alpha = 0
            addChild(w)
            w.run(.sequence([
                .wait(forDuration: BossAttackHitbox.telegraphPerCell * Double(i)),
                .fadeIn(withDuration: 0.08)
            ]))
        }

        let totalTelegraph = BossAttackHitbox.telegraphPerCell * Double(sweepOrder.count)
                           + BossAttackHitbox.telegraphTail

        // 3. Activate: remove warnings + single combined hitbox grows from portal
        run(.sequence([
            .wait(forDuration: totalTelegraph),
            .run { [weak self] in
                guard let self = self else { return }
                self.children.filter { $0.name == "warning" }.forEach { $0.removeFromParent() }
                portal.removeFromParent()
                self.spawnCombinedHitbox(cells: cells, cellSize: cellSize,
                                         imageName: hitboxImage, horizontal: horizontal,
                                         onExpire: onExpire)
            }
        ]))
    }

    // MARK: - Combined single hitbox

    private func spawnCombinedHitbox(cells: [CGPoint], cellSize: CGSize,
                                     imageName: String, horizontal: Bool,
                                     onExpire: (() -> Void)?) {
        let count = CGFloat(cells.count)

        let combinedSize: CGSize
        let combinedCenter: CGPoint
        let anchorPt: CGPoint

        if horizontal {
            // Full row: wide as all cells, anchored at the right edge (portal side)
            combinedSize   = CGSize(width: cellSize.width * count, height: cellSize.height)
            let rightEdge  = (cells.last?.x ?? 0) + cellSize.width / 2
            combinedCenter = CGPoint(x: rightEdge, y: cells[0].y)
            anchorPt       = CGPoint(x: 1.0, y: 0.5)
        } else {
            // Full column: tall as all cells, anchored at the bottom edge (portal side)
            combinedSize   = CGSize(width: cellSize.width, height: cellSize.height * count)
            let bottomEdge = (cells.first?.y ?? 0) - cellSize.height / 2
            combinedCenter = CGPoint(x: cells[0].x, y: bottomEdge)
            anchorPt       = CGPoint(x: 0.5, y: 0.0)
        }

        let tex = SKTexture(imageNamed: imageName)
        tex.filteringMode = .nearest
        let hitbox = SKSpriteNode(texture: tex, color: .clear, size: combinedSize)
        hitbox.anchorPoint = anchorPt
        hitbox.position    = combinedCenter
        hitbox.name        = "bossAttackLive"

        // Grow from portal (scale along the growth axis)
        if horizontal {
            hitbox.xScale = 0
            hitbox.run(.scaleX(to: 1.0, duration: BossAttackHitbox.growDuration))
        } else {
            hitbox.yScale = 0
            hitbox.run(.scaleY(to: 1.0, duration: BossAttackHitbox.growDuration))
        }

        // Physics body covers the full combined area (centered in the node)
        let bodyCenter: CGPoint
        if horizontal {
            bodyCenter = CGPoint(x: -combinedSize.width / 2, y: 0)
        } else {
            bodyCenter = CGPoint(x: 0, y: combinedSize.height / 2)
        }
        let body = SKPhysicsBody(rectangleOf: combinedSize, center: bodyCenter)
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask    = PhysicsCategory.bossAttack
        body.collisionBitMask   = 0
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        hitbox.physicsBody = body

        addChild(hitbox)

        // Expire after hold duration
        let totalActive = BossAttackHitbox.growDuration + BossAttackHitbox.holdDuration
        run(.sequence([
            .wait(forDuration: totalActive),
            .run { onExpire?() },
            .removeFromParent()
        ]))
    }

    // MARK: - Helpers

    private func makePortal(at point: CGPoint, size: CGSize) -> SKSpriteNode {
        let tex = SKTexture(imageNamed: "portalBoss")
        tex.filteringMode = .nearest
        let n = SKSpriteNode(texture: tex, color: .clear,
                             size: CGSize(width: size.height, height: size.height))
        n.position = point
        n.name = "portal"
        n.alpha = 0
        n.run(.sequence([
            .fadeIn(withDuration: 0.1),
            .repeatForever(.sequence([
                .scale(to: 1.1, duration: 0.18),
                .scale(to: 1.0, duration: 0.18)
            ]))
        ]))
        return n
    }

    private func makeWarning(at point: CGPoint, size: CGSize) -> SKSpriteNode {
        let tex = SKTexture(imageNamed: "warningSign")
        tex.filteringMode = .nearest
        let n = SKSpriteNode(texture: tex, color: .clear, size: size)
        n.position = point
        n.name = "warning"
        n.run(.repeatForever(.sequence([
            .scale(to: 1.05, duration: 0.18),
            .scale(to: 1.00, duration: 0.18)
        ])))
        return n
    }
}
