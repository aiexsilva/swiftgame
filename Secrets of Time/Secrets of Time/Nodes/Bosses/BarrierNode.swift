import SpriteKit

/// Vertical barrier separating the player from the boss body. Blocks the
/// player but allows the player's attack hitbox (projectile) to pass through.
/// Takes 3 hits before fading out.
final class BarrierNode: SKSpriteNode {

    private(set) var hitsRemaining: Int = 3
    var onBroken: (() -> Void)?
    private(set) var isBroken: Bool = false

    init(at worldPosition: CGPoint) {
        let displaySize = CGSize(width: 32, height: 360)
        super.init(texture: nil, color: SKColor(white: 0.25, alpha: 1.0), size: displaySize)
        position = worldPosition
        name = "barrier"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        zPosition = 0
        setupGlow(size: displaySize)
        setupPhysics(size: displaySize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGlow(size: CGSize) {
        let glow = SKShapeNode(
            rectOf: CGSize(width: size.width * 1.4, height: size.height * 1.02),
            cornerRadius: 6
        )
        glow.fillColor = SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.18)
        glow.strokeColor = SKColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.6)
        glow.lineWidth = 2
        glow.position = CGPoint(x: 0, y: size.height / 2)
        glow.zPosition = -1
        glow.name = "barrierGlow"
        addChild(glow)
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.7),
            .fadeAlpha(to: 0.18, duration: 0.7)
        ])))
    }

    private func setupPhysics(size: CGSize) {
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.barrier
        // Player collides; the projectile passes through.
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = 0
        physicsBody = body
    }

    /// Called by the scene when the player's projectile hits an active
    /// vertical boss attack. Returns true if the barrier broke on this hit.
    @discardableResult
    func registerHit() -> Bool {
        guard !isBroken else { return false }
        hitsRemaining = max(0, hitsRemaining - 1)
        // Quick flash + shake to acknowledge the hit.
        run(.sequence([
            .colorize(with: .red, colorBlendFactor: 0.5, duration: 0.05),
            .colorize(withColorBlendFactor: 0.0, duration: 0.18)
        ]))
        if hitsRemaining <= 0 {
            isBroken = true
            physicsBody = nil
            run(.sequence([
                .fadeOut(withDuration: 0.4),
                .run { [weak self] in self?.onBroken?() },
                .removeFromParent()
            ]))
            return true
        }
        return false
    }
}
