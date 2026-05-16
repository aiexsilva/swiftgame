import SpriteKit

/// Base class shared by all enemies. Handles physics, health/damage, debug
/// hitbox and a death callback. Each enemy subclass overrides `update(...)`
/// to implement its specific behavior (patrol, jump, chase, …).
class EnemyNode: SKSpriteNode {

    // MARK: - Health
    private(set) var hitPoints: Int
    let maxHitPoints: Int
    let isImmortal: Bool
    private(set) var isDead: Bool = false

    /// Called when the enemy dies. The scene uses this to drop the enemy
    /// from its active list so updates stop firing on it.
    var onDeath: ((EnemyNode) -> Void)?

    // MARK: - Body config
    let bodySize: CGSize
    let bodyCenter: CGPoint
    let isAffectedByGravity: Bool

    /// Toggle to draw a red outline around the physics body for visual debugging.
    static var showDebugHitbox: Bool = true

    // MARK: - Init
    init(
        texture: SKTexture,
        displaySize: CGSize,
        bodySize: CGSize,
        bodyCenterY: CGFloat,
        anchorY: CGFloat = 0,
        isAffectedByGravity: Bool = false,
        hp: Int = 1,
        isImmortal: Bool = false
    ) {
        self.bodySize = bodySize
        self.bodyCenter = CGPoint(x: 0, y: bodyCenterY)
        self.isAffectedByGravity = isAffectedByGravity
        self.hitPoints = hp
        self.maxHitPoints = hp
        self.isImmortal = isImmortal

        super.init(texture: texture, color: .clear, size: displaySize)
        anchorPoint = CGPoint(x: 0.5, y: anchorY)
        name = "enemy"
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Physics
    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: bodySize, center: bodyCenter)
        // Dynamic only when gravity matters (e.g. the jumper). Otherwise the
        // enemy is moved via `position` and stays kinematic.
        body.isDynamic = isAffectedByGravity
        body.affectedByGravity = isAffectedByGravity
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.categoryBitMask = PhysicsCategory.enemy
        body.collisionBitMask = isAffectedByGravity ? PhysicsCategory.platform : PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        physicsBody = body

        if EnemyNode.showDebugHitbox {
            let outline = SKShapeNode(rectOf: bodySize)
            outline.strokeColor = .red
            outline.lineWidth = 1
            outline.fillColor = .clear
            outline.position = bodyCenter
            outline.zPosition = 100
            outline.name = "debugHitbox"
            addChild(outline)
        }
    }

    // MARK: - Damage
    func takeDamage(_ amount: Int = 1) {
        guard !isDead else { return }
        if isImmortal {
            // Visual feedback only.
            run(.sequence([
                .colorize(with: .white, colorBlendFactor: 0.4, duration: 0.05),
                .colorize(withColorBlendFactor: 0.0, duration: 0.1)
            ]))
            return
        }
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

    // MARK: - Behavior
    /// Override in subclasses to implement movement / AI.
    /// `playerPosition` is provided for enemies that need to react to the player.
    func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        // Default: no-op.
    }

    // MARK: - Helpers
    /// Solid-color texture for placeholder enemy sprites.
    static func placeholderTexture(size: CGSize, color: SKColor) -> SKTexture {
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
        let t = SKTexture(image: image)
        t.filteringMode = .nearest
        return t
    }
}
