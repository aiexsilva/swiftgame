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

    // MARK: - Sprite
    private static let displaySize = CGSize(width: 48, height: 48)
    /// Smaller than the sprite — the slime's actual collidable mass.
    private static let bodySize = CGSize(width: 38, height: 28)
    private static let slimeTextures: [SKTexture] = {
        (1...7).map { i in
            let t = SKTexture(imageNamed: "Artboard \(i)")
            t.filteringMode = .nearest
            return t
        }
    }()

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        let texture = EnemyNode.slimeTextures.first ?? SKTexture()
        super.init(texture: texture, color: .clear, size: EnemyNode.displaySize)
        // Anchor at the visible base of the slime body
        anchorPoint = CGPoint(x: 0.5, y: 0.25)
        name = "enemy"
        setupPhysics()
        run(.repeatForever(.animate(
            with: EnemyNode.slimeTextures,
            timePerFrame: 0.12, resize: false, restore: false
        )), withKey: "slimeAnim")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupPhysics() {
        // Body bottom aligned with the sprite's bottom (node origin).
        let body = SKPhysicsBody(
            rectangleOf: EnemyNode.bodySize,
            center: CGPoint(x: 0, y: EnemyNode.bodySize.height / 2)
        )
        body.isDynamic = false
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        physicsBody = body

        if EnemyNode.showDebugHitbox {
            let outline = SKShapeNode(rectOf: EnemyNode.bodySize)
            outline.strokeColor = .red
            outline.lineWidth = 1
            outline.fillColor = .clear
            outline.position = CGPoint(x: 0, y: EnemyNode.bodySize.height / 2)
            outline.zPosition = 100
            outline.name = "debugHitbox"
            addChild(outline)
        }
    }

    static var showDebugHitbox: Bool = true

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
