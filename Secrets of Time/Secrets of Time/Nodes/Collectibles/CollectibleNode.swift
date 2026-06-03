//
//  CollectibleNode.swift
//  Secrets of Time
//
//  Peça de puzzle que o jogador apanha para desbloquear o portal de saída do nível.
//  Cada instância usa um índice único (1–4) para escolher a sprite correspondente
//  (Puzzle1.png … Puzzle4.png). Ao ser apanhada exibe uma animação de escala/fade
//  e desaparece da cena.
//

import SpriteKit

/// Peça de puzzle coleccionável. Desbloqueia o portal ao ser apanhada.
final class CollectibleNode: SKSpriteNode {

    /// Index of the puzzle piece this pickup represents (1-based).
    let pieceIndex: Int

    static func texture(for pieceIndex: Int) -> SKTexture {
        let t = SKTexture(imageNamed: "Puzzle\(pieceIndex)")
        t.filteringMode = .nearest
        return t
    }

    init(at worldPosition: CGPoint, pieceIndex: Int) {
        self.pieceIndex = pieceIndex
        let displaySize = CGSize(width: 30, height: 30)
        let tex = CollectibleNode.texture(for: pieceIndex)
        super.init(texture: tex, color: .clear, size: displaySize)
        position = worldPosition
        name = "collectible"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        zPosition = 1

        // Gentle bob so the pickup reads as interactive.
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 4, duration: 0.8),
            .moveBy(x: 0, y: -4, duration: 0.8)
        ])
        run(.repeatForever(bob))

        setupPhysics(size: displaySize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics(size: CGSize) {
        // Hitbox centered on the visible square (anchor is bottom-center).
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.collectible
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    /// Visual pickup feedback then despawn.
    func collect() {
        removeAllActions()
        physicsBody = nil
        run(.sequence([
            .group([
                .scale(to: 1.6, duration: 0.18),
                .fadeOut(withDuration: 0.18)
            ]),
            .removeFromParent()
        ]))
    }
}
