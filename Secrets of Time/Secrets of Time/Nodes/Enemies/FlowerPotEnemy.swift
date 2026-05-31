import SpriteKit

/// Trap-style enemy: idles in mid-air, falls when the player walks under it,
/// damages on impact mid-fall, and turns into a static prop after landing.
///
/// The fall is "anticipated" — a short look-ahead based on the player's
/// horizontal velocity triggers the drop slightly before the player is
/// directly under the pot, giving the trap a chance to actually land on them.
class FlowerPotEnemy: EnemyNode {

    // MARK: - Tuning
    /// Half-width of the trigger zone (in scene units).
    private let triggerHalfWidth: CGFloat = 35
    /// Seconds of look-ahead applied to the player's velocity.
    private let lookaheadTime: CGFloat = 0.25

    // MARK: - State
    private enum State { case idle, falling, landed }
    private var state: State = .idle

    private var lastPlayerX: CGFloat = .greatestFiniteMagnitude

    // MARK: - Animations
    /// Idle animation as a ping-pong: frames 1→5 then 5→1, so the loop
    /// doesn't snap back from frame 5 to frame 1 each cycle.
    private static let idleTextures: [SKTexture] = {
        let forward: [SKTexture] = (1...5).map { i in
            let t = SKTexture(imageNamed: "PotIdle\(i)")
            t.filteringMode = .nearest
            return t
        }
        // 1,2,3,4,5,4,3,2 — drop the duplicated endpoints so the cycle is smooth.
        let backward = Array(forward.dropFirst().dropLast().reversed())
        return forward + backward
    }()
    private static let fallingTextures: [SKTexture] = (1...6).map { i in
        let t = SKTexture(imageNamed: "PotFall\(i)")
        t.filteringMode = .nearest
        return t
    }

    init() {
        let displaySize = CGSize(width: 56, height: 56)
        super.init(
            texture: FlowerPotEnemy.idleTextures.first ?? SKTexture(),
            displaySize: displaySize,
            bodySize: CGSize(width: 36, height: 40),
            bodyCenterY: 20,
            anchorY: 0,
            isAffectedByGravity: false,
            hp: 1,
            isImmortal: true   // a trap, not killable
        )
        run(.repeatForever(.animate(
            with: FlowerPotEnemy.idleTextures,
            timePerFrame: 0.18, resize: false, restore: false
        )), withKey: "potAnim")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Behavior
    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead else { return }

        switch state {
        case .idle:
            // Estimate player velocity from the position delta to "predict"
            // where they'll be in `lookaheadTime` seconds.
            let dt = max(CGFloat(deltaTime), 0.0001)
            let vx: CGFloat
            if lastPlayerX == .greatestFiniteMagnitude {
                vx = 0
            } else {
                vx = (playerPosition.x - lastPlayerX) / dt
            }
            lastPlayerX = playerPosition.x

            let predictedX = playerPosition.x + vx * lookaheadTime
            if abs(predictedX - position.x) <= triggerHalfWidth {
                startFalling()
            }

        case .falling:
            // Refuse to "float": if any collision response slowed the pot, kick
            // it downward again. Player has no entry in the pot's collisionBitMask,
            // but this is belt-and-suspenders against weird physics interactions.
            if let body = physicsBody, body.velocity.dy > -100 {
                body.velocity = CGVector(dx: 0, dy: -350)
            }

        case .landed:
            break
        }
    }

    private func startFalling() {
        guard state == .idle else { return }
        state = .falling

        removeAction(forKey: "potAnim")
        run(.animate(with: FlowerPotEnemy.fallingTextures,
                     timePerFrame: 0.08, resize: false, restore: false),
            withKey: "potAnim")

        // Enable gravity. Keep collision only with the ground (let it pass
        // through platforms / walls / player so the player gets damaged on contact).
        guard let body = physicsBody else { return }
        body.isDynamic = true
        body.affectedByGravity = true
        body.collisionBitMask = PhysicsCategory.ground
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.ground
        // Kick the pot downward immediately so it drops fast instead of
        // accelerating from rest under the scene's modest gravity.
        body.velocity = CGVector(dx: 0, dy: -350)
    }

    /// Called by the scene when the pot contacts the ground.
    func land() {
        guard state == .falling else { return }
        state = .landed

        // Freeze on the last falling frame and become an inert prop.
        removeAction(forKey: "potAnim")
        if let last = FlowerPotEnemy.fallingTextures.last { texture = last }

        // Stop physics interaction — no more damage to the player.
        physicsBody = nil

        // Hold the broken-pot frame for 3 seconds, then fade out and despawn.
        run(.sequence([
            .wait(forDuration: 3.0),
            .fadeOut(withDuration: 0.5),
            .removeFromParent()
        ]))
    }
}
