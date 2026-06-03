//
//  PenguinEnemy.swift
//  Secrets of Time
//
//  Fast-charging enemy that slides back and forth between two horizontal
//  boundaries, briefly pausing before reversing direction. Appears in
//  the Winter level (Level 4).
//

import SpriteKit

/// Fast-charging enemy that bounces between `minX` and `maxX`.
/// On each boundary hit it pauses briefly then reverses, mimicking a
/// penguin sliding on ice.
final class PenguinEnemy: EnemyNode {

    private let moveSpeed: CGFloat = 220  // horizontal speed in scene units/sec
    private let minX: CGFloat
    private let maxX: CGFloat
    private var direction: CGFloat = 1    // +1 = moving right, -1 = moving left
    private var pausing: Bool = false     // true while the turn-around pause is active

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        let displaySize = CGSize(width: 40, height: 44)
        let tex = SKTexture(imageNamed: "pingu")
        tex.filteringMode = .nearest
        super.init(
            texture: tex,
            displaySize: displaySize,
            bodySize: CGSize(width: 32, height: 38),
            bodyCenterY: 19,
            anchorY: 0.0,
            isAffectedByGravity: true,
            hp: 2
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead, !pausing else { return }

        // Drive horizontal velocity directly so gravity still applies
        physicsBody?.velocity.dx = direction * moveSpeed

        // Reverse on boundary hit
        if position.x >= maxX {
            position.x = maxX
            reverse()
        } else if position.x <= minX {
            position.x = minX
            reverse()
        }

        // Flip sprite to match movement direction
        xScale = direction > 0 ? abs(xScale) : -abs(xScale)
    }

    /// Stops movement, waits 0.25 s, then flips direction.
    private func reverse() {
        guard !pausing else { return }
        pausing = true
        physicsBody?.velocity.dx = 0
        run(.sequence([
            .wait(forDuration: 0.25),
            .run { [weak self] in
                guard let self = self else { return }
                self.direction *= -1
                self.pausing = false
            }
        ]))
    }
}
