import SpriteKit

/// Simple patrol enemy: walks back and forth between `minX` and `maxX`.
class EnemyNode: SKSpriteNode {

    private let moveSpeed: CGFloat = 80.0
    private let minX: CGFloat
    private let maxX: CGFloat
    private var direction: CGFloat = 1  // +1 right, -1 left

    private(set) var hitPoints: Int = 1
    private(set) var isDead: Bool = false

    /// Called when the enemy dies. The scene uses this to remove the enemy
    /// from its active list so it stops being updated.
    var onDeath: ((EnemyNode) -> Void)?

    func takeDamage(_ amount: Int = 1) {
        guard !isDead else { return }
        hitPoints -= amount
        run(.sequence([
            .colorize(with: .white, colorBlendFactor: 0.8, duration: 0.05),
            .colorize(withColorBlendFactor: 0.0, duration: 0.1)
        ]))
        if hitPoints <= 0 {
            isDead = true
            physicsBody = nil
            onDeath?(self)
            run(.sequence([.fadeOut(withDuration: 0.15), .removeFromParent()]))
        }
    }

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        let size = CGSize(width: 40, height: 40)
        let texture = EnemyNode.placeholderTexture(size: size, color: .systemRed)
        super.init(texture: texture, color: .clear, size: size)
        name = "enemy"
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private static func placeholderTexture(size: CGSize, color: SKColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        return SKTexture(image: image)
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = false
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        physicsBody = body
    }

    func update(deltaTime: TimeInterval) {
        guard !isDead else { return }
        let dt = CGFloat(deltaTime)
        var newX = position.x + direction * moveSpeed * dt

        if newX >= maxX {
            newX = maxX
            direction = -1
            xScale = -abs(xScale)
        } else if newX <= minX {
            newX = minX
            direction = 1
            xScale = abs(xScale)
        }
        position.x = newX
    }
}
