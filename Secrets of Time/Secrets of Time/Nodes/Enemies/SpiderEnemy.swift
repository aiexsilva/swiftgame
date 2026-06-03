//
//  SpiderEnemy.swift
//  Secrets of Time
//
//  An immortal hazard that hangs between a platform and the ground,
//  oscillating slowly up and down like a spider on a web.
//  The player cannot destroy it — only avoid it.
//

import SpriteKit

/// Immortal hazard anchored between a platform and the ground.
/// Movement is driven entirely by SKAction (not physics), so the body
/// acts as a pure sensor: it detects contact with the player/projectiles
/// but never interacts with the physics simulation.
final class SpiderEnemy: EnemyNode {

    /// - Parameters:
    ///   - x: Horizontal position (typically the same X as the platform above).
    ///   - platformY: Center-Y of the platform the spider hangs from (height assumed 24 pt).
    ///   - groundY: Y of the floor below (default ground surface ≈ 60).
    init(x: CGFloat, platformY: CGFloat, groundY: CGFloat = 60) {
        let displaySize = CGSize(width: 32, height: 32)
        let tex = SKTexture(imageNamed: "aranha")
        tex.filteringMode = .nearest
        super.init(
            texture: tex,
            displaySize: displaySize,
            bodySize: CGSize(width: 28, height: 28),
            bodyCenterY: 14,
            anchorY: 0.0,
            isAffectedByGravity: false,  // moved by SKAction, not physics
            hp: 1,
            isImmortal: true             // cannot be destroyed
        )

        // Compute the gap between platform bottom and ground, leaving a small buffer
        let platformBottom = platformY - 12  // half of platform height (24 pt)
        let buffer: CGFloat = 10
        let topY    = platformBottom - buffer
        let bottomY = groundY + buffer
        let midY    = (topY + bottomY) / 2
        let amplitude = (topY - bottomY) / 2

        position = CGPoint(x: x, y: midY)

        // Override physics to pure sensor: no collisions, only contact events
        if let body = physicsBody {
            body.isDynamic = false
            body.affectedByGravity = false
            body.collisionBitMask = PhysicsCategory.none
        }

        guard amplitude > 4 else { return }  // gap too small to oscillate

        // Slow eased oscillation — 2 s per leg gives a relaxed swing
        let moveUp   = SKAction.moveBy(x: 0, y:  amplitude, duration: 2.0)
        let moveDown = SKAction.moveBy(x: 0, y: -amplitude, duration: 2.0)
        moveUp.timingMode   = .easeInEaseOut
        moveDown.timingMode = .easeInEaseOut
        run(.repeatForever(.sequence([moveUp, moveDown])), withKey: "spiderOscillate")
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // No AI update needed — movement is handled by the SKAction above
    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {}
}
