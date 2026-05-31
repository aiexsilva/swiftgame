import SpriteKit

/// Pickup that increments the collectible counter and heals the player when
/// the player touches it. Placeholder visual — small yellow rounded square
/// with a glow ring. Replace the texture later.
final class CollectibleNode: SKSpriteNode {

    init(at worldPosition: CGPoint) {
        let displaySize = CGSize(width: 28, height: 28)
        super.init(texture: nil, color: .systemYellow, size: displaySize)
        position = worldPosition
        name = "collectible"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        zPosition = 1

        // Soft glow ring behind the square.
        let glow = SKShapeNode(circleOfRadius: 22)
        glow.fillColor = SKColor(red: 1.0, green: 0.92, blue: 0.35, alpha: 0.25)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: displaySize.height / 2)
        glow.zPosition = -1
        addChild(glow)

        // Gentle bob so the pickup reads as interactive.
        let bob = SKAction.sequence([
            .moveBy(x: 0, y: 4, duration: 0.6),
            .moveBy(x: 0, y: -4, duration: 0.6)
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
