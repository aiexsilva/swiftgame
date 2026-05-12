import SpriteKit

class PlayerNode: SKSpriteNode {

    // MARK: - Tuning
    private let moveSpeed: CGFloat = 300.0
    private let jumpImpulse: CGFloat = 65.0
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

    // MARK: - Health
    let maxHitPoints: Int = 3
    private(set) var hitPoints: Int = 3
    var onHealthChanged: ((_ current: Int, _ max: Int) -> Void)?

    func takeDamage(_ amount: Int = 1) {
        guard hitPoints > 0 else { return }
        hitPoints = max(0, hitPoints - amount)
        onHealthChanged?(hitPoints, maxHitPoints)
        if hitPoints <= 0 {
            play(.dying)
        } else {
            play(.hit)
            // After a short stagger, locomotion update will resume choosing anims.
            run(.wait(forDuration: 0.2)) { [weak self] in
                if self?.currentAnim == .hit { self?.currentAnim = nil }
            }
        }
    }

    func heal(_ amount: Int = 1) {
        guard hitPoints < maxHitPoints else { return }
        hitPoints = min(maxHitPoints, hitPoints + amount)
        onHealthChanged?(hitPoints, maxHitPoints)
    }

    func resetHealth() {
        hitPoints = maxHitPoints
        onHealthChanged?(hitPoints, maxHitPoints)
        currentAnim = nil
        removeAction(forKey: PlayerNode.animKey)
        play(.idle)
    }

    /// Pushes the player away from a hit source. `direction` is +1 (right) or -1 (left).
    func applyHitKnockback(direction: CGFloat) {
        guard let body = physicsBody else { return }
        let horizontal: CGFloat = 25
        let vertical: CGFloat = 35
        body.velocity = CGVector(dx: 0, dy: 0)
        body.applyImpulse(CGVector(dx: direction * horizontal, dy: vertical))
    }

    // MARK: - Attack
    private let attackDuration: TimeInterval = 0.15
    private let attackCooldown: TimeInterval = 0.35
    private let attackReach: CGFloat = 100
    private let attackHeight: CGFloat = 30
    private var attackCooldownRemaining: TimeInterval = 0

    /// Spawns a short-lived hitbox in front of the player.
    /// Returns the node so the scene can add it as a child (kept in scene-space so
    /// the player's xScale flip doesn't affect the physics body).
    func performAttack() -> SKNode? {
        guard attackCooldownRemaining <= 0 else { return nil }
        attackCooldownRemaining = attackCooldown

        let hitboxSize = CGSize(width: attackReach, height: attackHeight)
        let hitbox = SKSpriteNode(color: SKColor(white: 1.0, alpha: 0.4), size: hitboxSize)
        hitbox.name = "playerAttack"
        let dir: CGFloat = facingRight ? 1 : -1
        hitbox.position = CGPoint(
            x: position.x + dir * (PlayerNode.bodySize.width / 2 + attackReach / 2),
            y: position.y
        )

        let body = SKPhysicsBody(rectangleOf: hitboxSize)
        // Must be dynamic — two static bodies don't generate contact events.
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.linearDamping = 0
        body.angularDamping = 0
        body.categoryBitMask = PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.enemy
        hitbox.physicsBody = body

        hitbox.run(.sequence([.wait(forDuration: attackDuration), .removeFromParent()]))
        return hitbox
    }

    private func updateAttackCooldown(deltaTime: TimeInterval) {
        if attackCooldownRemaining > 0 {
            attackCooldownRemaining -= deltaTime
        }
    }

    // MARK: - Animation control

    private static let animKey = "playerAnim"

    private func play(_ state: AnimState) {
        guard currentAnim != state else { return }
        currentAnim = state
        removeAction(forKey: PlayerNode.animKey)
        switch state {
        case .idle:
            run(.repeatForever(.animate(with: PlayerNode.idleTextures, timePerFrame: 0.12, resize: false, restore: false)), withKey: PlayerNode.animKey)
        case .run:
            run(.repeatForever(.animate(with: PlayerNode.runTextures, timePerFrame: 0.08, resize: false, restore: false)), withKey: PlayerNode.animKey)
        case .rising:
            run(.animate(with: PlayerNode.risingTextures, timePerFrame: 0.08, resize: false, restore: false), withKey: PlayerNode.animKey)
        case .falling:
            run(.animate(with: PlayerNode.fallingTextures, timePerFrame: 0.08, resize: false, restore: false), withKey: PlayerNode.animKey)
        case .hit:
            run(.animate(with: PlayerNode.hitTextures, timePerFrame: 0.06, resize: false, restore: false), withKey: PlayerNode.animKey)
        case .dying:
            run(.sequence([
                .animate(with: PlayerNode.dyingTextures, timePerFrame: 0.1, resize: false, restore: false),
                .run { [weak self] in self?.texture = PlayerNode.deadTexture; self?.currentAnim = .dead }
            ]), withKey: PlayerNode.animKey)
        case .dead:
            texture = PlayerNode.deadTexture
        }
    }

    private func chooseLocomotionAnim() {
        guard currentAnim != .hit, currentAnim != .dying, currentAnim != .dead else { return }
        guard let body = physicsBody else { return }
        let vy = body.velocity.dy
        if !isGrounded {
            play(vy > 30 ? .rising : .falling)
        } else if abs(body.velocity.dx) > 10 {
            play(.run)
        } else {
            play(.idle)
        }
    }

    /// 1.0 = normal ground (near-instant control). Lower values = icy / slippery.
    /// Set this from GameScene/LevelManager when entering a slippery surface (e.g. 0.15 for ice).
    var surfaceSlipperiness: CGFloat = 1.0

    // MARK: - Animations

    private enum AnimState { case idle, run, rising, falling, hit, dying, dead }
    private var currentAnim: AnimState?

    private static let idleTextures: [SKTexture]    = loadTextures(prefix: "Idle", count: 6)
    private static let runTextures: [SKTexture]     = loadTextures(prefix: "Run", count: 6)
    private static let risingTextures: [SKTexture]  = loadTextures(prefix: "Rising", count: 6)
    private static let fallingTextures: [SKTexture] = loadTextures(prefix: "Falling", count: 6)
    private static let hitTextures: [SKTexture]     = loadTextures(prefix: "Hit", count: 3)
    private static let dyingTextures: [SKTexture]   = loadTextures(prefix: "Dying", count: 6)
    private static let deadTexture: SKTexture       = {
        let t = SKTexture(imageNamed: "Dead")
        t.filteringMode = .nearest
        return t
    }()

    private static func loadTextures(prefix: String, count: Int) -> [SKTexture] {
        (1...count).map { i in
            let t = SKTexture(imageNamed: "\(prefix)\(i)")
            t.filteringMode = .nearest   // crisp pixel art
            return t
        }
    }

    // MARK: - Init

    /// Visual display size (sprites are 16x16 pixel art, scaled up).
    /// Sized so the visible character roughly fills the physics body.
    private static let displaySize = CGSize(width: 56, height: 56)
    /// Physics body (centered on the sprite).
    private static let bodySize = CGSize(width: 40, height: 52)

    init() {
        let texture = PlayerNode.idleTextures.first ?? SKTexture()
        super.init(texture: texture, color: .clear, size: PlayerNode.displaySize)
        name = "player"
        setupPhysics()
        play(.idle)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPhysics()
    }

    private func setupPhysics() {
        let body = SKPhysicsBody(rectangleOf: PlayerNode.bodySize)
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.linearDamping = 0.0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.enemy | PhysicsCategory.wall
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
        updateAttackCooldown(deltaTime: deltaTime)
        guard let body = physicsBody else { return }

        chooseLocomotionAnim()

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
