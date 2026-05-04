import SpriteKit

class PlayerNode: SKSpriteNode {

    // MARK: - Tuning
    private let moveSpeed: CGFloat = 300.0
    private let jumpImpulse: CGFloat = 80.0
    private let maxHorizontalSpeed: CGFloat = 320.0

    /// How fast the player reaches target speed on solid ground (units/sec²).
    /// High value = responsive feel. Multiplied by `surfaceSlipperiness` at runtime.
    private let groundAccel: CGFloat = 2400.0
    /// Air control acceleration (independent of surface slipperiness).
    private let airAccel: CGFloat = 1200.0

    // MARK: - State
    private(set) var facingRight: Bool = true
    private(set) var isGrounded: Bool = false
    private var moveDirection: CGFloat = 0   // -1, 0, +1
    private var groundContacts: Int = 0      // counts platform contacts

    /// 1.0 = normal ground (near-instant control). Lower values = icy / slippery.
    /// Set this from GameScene/LevelManager when entering a slippery surface (e.g. 0.15 for ice).
    var surfaceSlipperiness: CGFloat = 1.0

    // MARK: - Init

    /// Use placeholder color box. When sprites are ready, swap `placeholderTexture()`
    /// for `SKTexture(imageNamed: "player_idle")` (or use `init(texture:)`).
    init() {
        let size = CGSize(width: 40, height: 60)
        let texture = PlayerNode.placeholderTexture(size: size, color: .systemTeal)
        super.init(texture: texture, color: .clear, size: size)
        name = "player"
        setupPhysics()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPhysics()
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
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.linearDamping = 0.0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.platform
        body.contactTestBitMask = PhysicsCategory.platform | PhysicsCategory.enemy
            | PhysicsCategory.artifact | PhysicsCategory.teleport
        physicsBody = body
    }

    // MARK: - Input API (called by GameScene from on-screen buttons)

    func startMoving(direction: CGFloat) {
        moveDirection = direction
        if direction > 0 { facingRight = true; xScale = abs(xScale) }
        if direction < 0 { facingRight = false; xScale = -abs(xScale) }
    }

    func stopMoving() {
        moveDirection = 0
    }

    func jump() {
        guard isGrounded, let body = physicsBody else { return }
        body.velocity = CGVector(dx: body.velocity.dx, dy: 0)
        body.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
        isGrounded = false
    }

    // MARK: - Per-frame update (called from GameScene.update)

    func update(deltaTime: TimeInterval) {
        guard let body = physicsBody else { return }

        let dt = CGFloat(deltaTime)
        let targetVx = moveDirection * moveSpeed
        let baseAccel = isGrounded ? groundAccel : airAccel
        let accel = baseAccel * surfaceSlipperiness
        let currentVx = body.velocity.dx
        let diff = targetVx - currentVx
        let maxStep = accel * dt
        let step = max(-maxStep, min(maxStep, diff))
        var newVx = currentVx + step

        if abs(newVx) > maxHorizontalSpeed {
            newVx = newVx < 0 ? -maxHorizontalSpeed : maxHorizontalSpeed
        }
        body.velocity = CGVector(dx: newVx, dy: body.velocity.dy)
    }

    // MARK: - Contact callbacks (called by GameScene's contact delegate)

    func didBeginContactWithPlatform() {
        groundContacts += 1
        isGrounded = true
    }

    func didEndContactWithPlatform() {
        groundContacts = max(0, groundContacts - 1)
        if groundContacts == 0 {
            isGrounded = false
        }
    }
}
