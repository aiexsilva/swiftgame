//
//  BossNode.swift
//  Secrets of Time
//
//  The final boss character. Sits behind the BarrierNode and becomes
//  vulnerable only after the player destroys it by hitting 5 tentacles.
//  A single hit then triggers the defeat sequence.
//

import SpriteKit

/// Final boss. Plays an idle animation (boss1→boss2→boss3→boss2 loop) and
/// becomes vulnerable once the barrier is broken. One projectile hit defeats it.
final class BossNode: SKSpriteNode {

    var hitPoints: Int = 1
    /// Called when the boss is defeated so the scene can show the victory screen.
    var onDefeat: (() -> Void)?
    private(set) var isDefeated: Bool = false

    /// Ping-pong idle frames: 1 → 2 → 3 → 2 → repeat
    private static let idleTextures: [SKTexture] = {
        let names = ["boss1", "boss2", "boss3", "boss2"]
        return names.map { name in
            let t = SKTexture(imageNamed: name)
            t.filteringMode = .nearest
            return t
        }
    }()

    init(at worldPosition: CGPoint) {
        let tex = BossNode.idleTextures.first ?? SKTexture()
        let displaySize = CGSize(width: 160, height: 240)
        super.init(texture: tex, color: .clear, size: displaySize)
        position = worldPosition
        name = "boss"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)  // feet at position
        zPosition = 5
        setupPhysics(size: displaySize)

        // Start idle animation immediately
        run(.repeatForever(.animate(
            with: BossNode.idleTextures,
            timePerFrame: 0.18, resize: false, restore: false
        )), withKey: "bossIdle")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Physics

    private func setupPhysics(size: CGSize) {
        // Body centered vertically on the sprite (feet at y=0)
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask    = PhysicsCategory.bossBody
        body.collisionBitMask   = PhysicsCategory.player  // physically blocks the player
        body.contactTestBitMask = PhysicsCategory.player | PhysicsCategory.projectile
        physicsBody = body
    }

    // MARK: - Damage

    /// Called when the player's projectile hits the exposed boss body.
    /// Triggers the defeat animation and the `onDefeat` callback.
    func takeFinalHit() {
        guard !isDefeated else { return }
        hitPoints = max(0, hitPoints - 1)
        if hitPoints <= 0 {
            isDefeated = true
            physicsBody = nil                  // remove collisions immediately
            removeAction(forKey: "bossIdle")
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
