import SpriteKit

/// Placeholder boss body. Hidden behind a barrier until the player breaks it,
/// after which a single hit triggers the victory sequence via `onDefeat`.
final class BossNode: SKSpriteNode {

    var hitPoints: Int = 1
    var onDefeat: (() -> Void)?
    private(set) var isDefeated: Bool = false

    init(at worldPosition: CGPoint) {
        let displaySize = CGSize(width: 80, height: 140)
        super.init(texture: nil, color: .systemPurple, size: displaySize)
        position = worldPosition
        name = "boss"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        zPosition = 0
        setupPhysics(size: displaySize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics(size: CGSize) {
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.bossBody
        body.collisionBitMask = PhysicsCategory.player
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        physicsBody = body
    }

    /// Applies the final hit. The scene must have already broken the barrier
    /// before this is called.
    func takeFinalHit() {
        guard !isDefeated else { return }
        hitPoints = max(0, hitPoints - 1)
        if hitPoints <= 0 {
            isDefeated = true
            physicsBody = nil
            run(.sequence([
                .group([
                    .fadeOut(withDuration: 0.6),
                    .scale(to: 0.6, duration: 0.6)
                ]),
                .run { [weak self] in self?.onDefeat?() },
                .removeFromParent()
            ]))
        }
    }
}
