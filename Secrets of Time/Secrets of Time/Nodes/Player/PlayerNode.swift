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
    private let attackReach: CGFloat = 50
    private let attackHeight: CGFloat = 75
    private var attackCooldownRemaining: TimeInterval = 0
    /// Active attack hitbox, tracked so its position can follow the player while alive.
    private weak var activeAttackHitbox: SKNode?
    /// Facing direction captured at the moment the attack started (so swinging
    /// while turning doesn't flip the hitbox mid-swing).
    private var attackFacingRight: Bool = true

    /// Spawns a short-lived hitbox in front of the player.
    /// Returns the node so the scene can add it as a child (kept in scene-space so
    /// the player's xScale flip doesn't affect the physics body).
    func performAttack() -> SKNode? {
        guard attackCooldownRemaining <= 0 else { return nil }
        attackCooldownRemaining = attackCooldown
        play(.attack)

        attackFacingRight = facingRight
        let hitboxSize = CGSize(width: attackReach, height: attackHeight)
        let hitbox = SKSpriteNode(color: SKColor(white: 1.0, alpha: 0.4), size: hitboxSize)
        hitbox.name = "playerAttack"
        hitbox.position = attackHitboxPosition()

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

        if PlayerNode.showDebugHitbox {
            let outline = SKShapeNode(rectOf: hitboxSize)
            outline.strokeColor = .red
            outline.lineWidth = 1
            outline.fillColor = .clear
            hitbox.addChild(outline)
        }

        activeAttackHitbox = hitbox
        hitbox.run(.sequence([
            .wait(forDuration: attackDuration),
            .run { [weak self, weak hitbox] in
                if self?.activeAttackHitbox === hitbox { self?.activeAttackHitbox = nil }
            },
            .removeFromParent()
        ]))
        return hitbox
    }

    /// Position the attack hitbox should occupy each frame: in front of the
    /// player, anchored to the facing direction captured when the swing started.
    private func attackHitboxPosition() -> CGPoint {
        let dir: CGFloat = attackFacingRight ? 1 : -1
        return CGPoint(
            x: position.x + dir * (PlayerNode.bodySize.width / 2 + attackReach / 2),
            y: position.y + PlayerNode.bodySize.height / 2
        )
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
        // Any non-attack animation uses the standard display size. If we interrupt
        // an attack mid-swing (e.g. takeDamage → .hit), the cleanup `.run` block
        // never fires, so reset here to avoid the 2x scale leaking into other anims.
        if state != .attack {
            size = PlayerNode.displaySize
        }
        switch state {
        case .idle:
            run(.repeatForever(.animate(with: PlayerNode.idleTextures, timePerFrame: 0.12, resize: false, restore: false)), withKey: PlayerNode.animKey)
        case .run:
            run(.repeatForever(.animate(with: PlayerNode.runTextures, timePerFrame: 0.08, resize: false, restore: false)), withKey: PlayerNode.animKey)
        case .rising:
            run(.animate(with: PlayerNode.risingTextures, timePerFrame: 0.08, resize: false, restore: false), withKey: PlayerNode.animKey)
        case .falling:
            run(.animate(with: PlayerNode.fallingTextures, timePerFrame: 0.08, resize: false, restore: false), withKey: PlayerNode.animKey)
        case .attack:
            // AttackWood sprites are 32x32 (vs 16x16 for idle/run) but the character
            // fills less of the frame, so the on-screen character looks smaller at
            // the same node size. Enlarge so the visible character matches idle scale.
            let originalSize = size
            // AttackWood is 32x32 vs 16x16 for idle/run, so render at 2x size to
            // keep the same pixel-per-source ratio (otherwise the character
            // appears shrunk to half scale).
            let attackScale: CGFloat = 32.0 / 16.0
            size = CGSize(width: PlayerNode.displaySize.width * attackScale,
                          height: PlayerNode.displaySize.height * attackScale)
            run(.sequence([
                .animate(with: PlayerNode.attackTextures, timePerFrame: 0.06, resize: false, restore: false),
                .run { [weak self] in
                    self?.size = originalSize
                    if self?.currentAnim == .attack { self?.currentAnim = nil }
                }
            ]), withKey: PlayerNode.animKey)
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
        guard currentAnim != .attack, currentAnim != .hit,
              currentAnim != .dying, currentAnim != .dead else { return }
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

    private enum AnimState { case idle, run, rising, falling, attack, hit, dying, dead }
    private var currentAnim: AnimState?

    private static let idleTextures: [SKTexture]    = loadTextures(prefix: "Idle", count: 6)
    private static let runTextures: [SKTexture]     = loadTextures(prefix: "Run", count: 6)
    private static let risingTextures: [SKTexture]  = loadTextures(prefix: "Rising", count: 6)
    private static let fallingTextures: [SKTexture] = loadTextures(prefix: "Falling", count: 6)
    private static let hitTextures: [SKTexture]     = loadTextures(prefix: "Hit", count: 3)
    private static let attackTextures: [SKTexture]  = loadTextures(prefix: "AttackWood", count: 6)
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

    /// True while the attack animation is playing (used by external nodes like the staff).
    var isAttacking: Bool { currentAnim == .attack }

    init() {
        let texture = PlayerNode.idleTextures.first ?? SKTexture()
        super.init(texture: texture, color: .clear, size: PlayerNode.displaySize)
        // Anchor at bottom-center: node.position.y = the player's feet, which
        // is also the bottom of the hitbox. All other sprites in the game use
        // the same convention so they line up with the ground.
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        name = "player"
        zPosition = 10   // always drawn in front of NPCs / enemies
        setupPhysics()
        play(.idle)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupPhysics()
    }

    /// Toggle to draw a red outline around the physics body for visual debugging.
    static var showDebugHitbox: Bool = true

    private func addDebugHitbox(size: CGSize, center: CGPoint = .zero) {
        guard PlayerNode.showDebugHitbox else { return }
        let outline = SKShapeNode(rectOf: size)
        outline.strokeColor = .red
        outline.lineWidth = 1
        outline.fillColor = .clear
        outline.position = center
        outline.zPosition = 100
        outline.name = "debugHitbox"
        addChild(outline)
    }

    private func setupPhysics() {
        // Body bottom at node origin (= sprite bottom = feet) so the hitbox
        // aligns with the floor under the visible character.
        let body = SKPhysicsBody(
            rectangleOf: PlayerNode.bodySize,
            center: CGPoint(x: 0, y: PlayerNode.bodySize.height / 2)
        )
        body.allowsRotation = false
        body.restitution = 0.0
        body.friction = 0.0
        body.linearDamping = 0.0
        body.categoryBitMask = PhysicsCategory.player
        body.collisionBitMask = PhysicsCategory.platform | PhysicsCategory.enemy | PhysicsCategory.wall
        body.contactTestBitMask = PhysicsCategory.platform | PhysicsCategory.enemy
            | PhysicsCategory.artifact | PhysicsCategory.teleport
        physicsBody = body
        addDebugHitbox(
            size: PlayerNode.bodySize,
            center: CGPoint(x: 0, y: PlayerNode.bodySize.height / 2)
        )
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
        // Keep the active attack hitbox glued in front of the player so it
        // follows when the player moves mid-swing.
        if let hitbox = activeAttackHitbox {
            hitbox.position = attackHitboxPosition()
        }
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
