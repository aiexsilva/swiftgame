//
//  BarrierNode.swift
//  Secrets of Time
//
//  A tall vertical barrier that separates the player from the boss.
//  It does NOT take damage directly. Instead, GameScene counts how many
//  boss tentacles the player hits (5 required) and then calls
//  registerHit() three times to break the barrier immediately.
//

import SpriteKit

/// Protective barrier between the player and the boss.
/// Blocks the player physically but lets projectiles pass through.
/// Breaks after `registerHit()` is called 3 times (triggered externally
/// by GameScene once 5 tentacles have been destroyed).
final class BarrierNode: SKSpriteNode {

    private(set) var hitsRemaining: Int = 3
    /// Called once the barrier fully fades out and is removed.
    var onBroken: (() -> Void)?
    private(set) var isBroken: Bool = false

    init(at worldPosition: CGPoint) {
        // Tall enough that the player cannot jump over it
        let displaySize = CGSize(width: 32, height: 650)
        super.init(texture: nil,
                   color: SKColor(white: 0.25, alpha: 1.0),
                   size: displaySize)
        position = worldPosition
        name = "barrier"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)  // bottom edge at position.y
        zPosition = 0
        setupGlow(size: displaySize)
        setupPhysics(size: displaySize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Visual

    /// Blue pulsing glow around the barrier to make it visually distinct.
    private func setupGlow(size: CGSize) {
        let glow = SKShapeNode(
            rectOf: CGSize(width: size.width * 1.4, height: size.height * 1.02),
            cornerRadius: 6
        )
        glow.fillColor   = SKColor(red: 0.4, green: 0.6, blue: 1.0, alpha: 0.18)
        glow.strokeColor = SKColor(red: 0.5, green: 0.7, blue: 1.0, alpha: 0.6)
        glow.lineWidth   = 2
        glow.position    = CGPoint(x: 0, y: size.height / 2)
        glow.zPosition   = -1
        glow.name        = "barrierGlow"
        addChild(glow)
        // Animate the glow alpha so the barrier "breathes"
        glow.run(.repeatForever(.sequence([
            .fadeAlpha(to: 0.35, duration: 0.7),
            .fadeAlpha(to: 0.18, duration: 0.7)
        ])))
    }

    // MARK: - Physics

    private func setupPhysics(size: CGSize) {
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask    = PhysicsCategory.barrier
        body.collisionBitMask   = PhysicsCategory.player   // blocks player
        body.contactTestBitMask = 0   // barrier is broken via code, not contact events
        physicsBody = body
    }

    // MARK: - Damage

    /// Registers one hit. Called by GameScene (not by physics contact).
    /// After 3 hits the barrier fades out and `onBroken` fires.
    @discardableResult
    func registerHit() -> Bool {
        guard !isBroken else { return false }
        hitsRemaining = max(0, hitsRemaining - 1)

        // Visual hit flash
        run(.sequence([
            .colorize(with: .red, colorBlendFactor: 0.5, duration: 0.05),
            .colorize(withColorBlendFactor: 0.0, duration: 0.18)
        ]))

        if hitsRemaining <= 0 {
            isBroken = true
            physicsBody = nil   // no longer blocks the player
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
