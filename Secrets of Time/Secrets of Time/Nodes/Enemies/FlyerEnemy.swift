//
//  FlyerEnemy.swift
//  Secrets of Time
//
//  Inimigo voador do Nível 2 (Verão). Patrulha horizontalmente a uma
//  altitude fixa (sem gravidade), invertendo a direção nos limites.
//  Requer 2 ataques para ser eliminado.
//

import SpriteKit

/// Inimigo voador que patrulha horizontalmente a altitude fixa.
class FlyerEnemy: EnemyNode {

    private let moveSpeed: CGFloat = 170.0
    private let minX: CGFloat
    private let maxX: CGFloat
    private var direction: CGFloat = 1

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        let size = CGSize(width: 44, height: 36)
        let tex = SKTexture(imageNamed: "mosca")
        tex.filteringMode = .nearest
        super.init(
            texture: tex,
            displaySize: size,
            bodySize: size,
            bodyCenterY: size.height / 2,
            anchorY: 0,
            isAffectedByGravity: false,
            hp: 2
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead else { return }
        var newX = position.x + direction * moveSpeed * CGFloat(deltaTime)
        if newX >= maxX {
            newX = maxX; direction = -1; xScale = -abs(xScale)
        } else if newX <= minX {
            newX = minX; direction = 1; xScale = abs(xScale)
        }
        position.x = newX
    }
}
