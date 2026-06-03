//
//  EnemyProjectile.swift
//  Secrets of Time
//
//  A projectile fired by TurretEnemy. Moves horizontally at constant
//  speed, damages the player on contact, and self-destructs after 2 s.
//

import SpriteKit

/// Short-lived projectile launched by a TurretEnemy.
/// Moves horizontally, contacts only the player, and auto-removes after 2 s.
final class EnemyProjectile: SKSpriteNode {

    private static let speed: CGFloat = 300  // scene units per second

    /// - Parameters:
    ///   - worldPosition: Where the projectile spawns (usually the turret's barrel tip).
    ///   - direction: +1 to move right, -1 to move left.
    init(at worldPosition: CGPoint, direction: CGFloat) {
        let size = CGSize(width: 14, height: 14)
        let tex = EnemyNode.placeholderTexture(
            size: size,
            color: SKColor(red: 0.4, green: 0.85, blue: 1.0, alpha: 1.0)
        )
        super.init(texture: tex, color: .clear, size: size)
        position = worldPosition
        name = "enemyProjectile"
        zPosition = 5

        // Outline branca para destacar o projétil
        let outline = SKShapeNode(rectOf: size)
        outline.strokeColor = .white
        outline.lineWidth = 2
        outline.fillColor = .clear
        outline.zPosition = 1
        addChild(outline)

        // Physics: sensor only — no collisions, only player contact
        let body = SKPhysicsBody(rectangleOf: size)
        body.isDynamic = true
        body.affectedByGravity = false
        body.allowsRotation = false
        body.restitution = 0
        body.friction = 0
        body.categoryBitMask    = PhysicsCategory.enemyProjectile
        body.collisionBitMask   = PhysicsCategory.none
        body.contactTestBitMask = PhysicsCategory.player
        body.velocity = CGVector(dx: direction * EnemyProjectile.speed, dy: 0)
        physicsBody = body

        // Auto-despawn: short fade-out so the disappearance is not jarring
        run(.sequence([
            .wait(forDuration: 2.0),
            .fadeOut(withDuration: 0.15),
            .removeFromParent()
        ]))
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
