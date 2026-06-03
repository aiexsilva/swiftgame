//
//  BossAttackHitbox.swift
//  Secrets of Time
//
//  Hitboxes dos três tipos de ataque do boss:
//    • horizontal (pata linha) — hitbox 1×3 combinado, cresce da direita para a esquerda
//    • vertical  (tentáculo)   — hitbox 3×1 combinado, cresce de baixo para cima; persiste ao ser acertado
//    • single    (pata célula) — hitbox 1×1 com sprite de pata; desaparece ao ser acertado
//  Cada ataque exibe sinais de aviso antes de ativar a hitbox, dando ao jogador tempo para se esquivar.
//

import SpriteKit

/// Tipo de ataque do boss.
enum BossAttackKind {
    case horizontal  // pata linha 1×3 — remove quando acertada
    case vertical    // tentáculo 3×1 — persiste quando acertado
    case single      // pata célula 1×1 — remove quando acertada
}

/// Telegraph (warning signs) + hitbox ativa que cresce a partir de um portal.
final class BossAttackHitbox: SKNode {

    let kind: BossAttackKind

    static let telegraphPerCell: TimeInterval = 0.22
    static let telegraphTail:    TimeInterval = 0.35
    static let growDuration:     TimeInterval = 0.25
    static let holdDuration:     TimeInterval = 0.35

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

    /// Linha horizontal de patas (1×3). Portal à direita. Remove ao ser acertada.
    static func makeRow(cells: [CGPoint], cellSize: CGSize,
                        onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .horizontal)
        let sweepOrder = Array(cells.reversed())
        let rightEdge  = (cells.last?.x ?? 0) + cellSize.width / 2
        let portalPos  = CGPoint(x: rightEdge + 24, y: cells[0].y)
        node.runAttack(sweepOrder: sweepOrder, cells: cells,
                       cellSize: cellSize, portalPos: portalPos,
                       hitboxImage: "pata", horizontal: true, onExpire: onExpire)
        return node
    }

    /// Coluna vertical de tentáculos (3×1). Portal em baixo. Persiste ao ser acertado.
    static func makeColumn(cells: [CGPoint], cellSize: CGSize,
                           onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .vertical)
        let sweepOrder = cells
        let bottomEdge = (cells.first?.y ?? 0) - cellSize.height / 2
        let portalPos  = CGPoint(x: cells[0].x, y: bottomEdge - 24)
        node.runAttack(sweepOrder: sweepOrder, cells: cells,
                       cellSize: cellSize, portalPos: portalPos,
                       hitboxImage: "tentaculo", horizontal: false, onExpire: onExpire)
        return node
    }

    /// Pegada individual (1×1). Portal à direita da célula. Remove ao ser acertada.
    static func makeSingle(cell: CGPoint, cellSize: CGSize,
                           onExpire: (() -> Void)? = nil) -> BossAttackHitbox {
        let node = BossAttackHitbox(kind: .single)
        let portalPos = CGPoint(x: cell.x + cellSize.width / 2 + 24, y: cell.y)
        node.runAttack(sweepOrder: [cell], cells: [cell],
                       cellSize: cellSize, portalPos: portalPos,
                       hitboxImage: "pegada", horizontal: true, onExpire: onExpire)
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

        // 2. Warning signs — um por célula na ordem de varrimento
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

        // 3. Ativa: remove warnings + spawna hitbox combinada
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

    // MARK: - Hitbox combinada (usada por row, column e single)

    private func spawnCombinedHitbox(cells: [CGPoint], cellSize: CGSize,
                                     imageName: String, horizontal: Bool,
                                     onExpire: (() -> Void)?) {
        let count = CGFloat(cells.count)

        let combinedSize: CGSize
        let combinedCenter: CGPoint
        let anchorPt: CGPoint

        if horizontal {
            // Linha (ou célula única): largura total, âncora no lado direito (portal)
            combinedSize   = CGSize(width: cellSize.width * count, height: cellSize.height)
            let rightEdge  = (cells.last?.x ?? 0) + cellSize.width / 2
            combinedCenter = CGPoint(x: rightEdge, y: cells[0].y)
            anchorPt       = CGPoint(x: 1.0, y: 0.5)
        } else {
            // Coluna: altura total, âncora na base (portal)
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

        // Cresce a partir do portal
        if horizontal {
            hitbox.xScale = 0
            hitbox.run(.scaleX(to: 1.0, duration: BossAttackHitbox.growDuration))
        } else {
            hitbox.yScale = 0
            hitbox.run(.scaleY(to: 1.0, duration: BossAttackHitbox.growDuration))
        }

        // Physics body cobre a área combinada
        let bodyCenter: CGPoint = horizontal
            ? CGPoint(x: -combinedSize.width / 2, y: 0)
            : CGPoint(x: 0, y: combinedSize.height / 2)
        let body = SKPhysicsBody(rectangleOf: combinedSize, center: bodyCenter)
        body.isDynamic          = false
        body.affectedByGravity  = false
        body.allowsRotation     = false
        body.categoryBitMask    = PhysicsCategory.bossAttack
        body.collisionBitMask   = 0
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        hitbox.physicsBody = body

        addChild(hitbox)

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
