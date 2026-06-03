//
//  TurretEnemy.swift
//  Secrets of Time
//
//  A stationary, immortal enemy that periodically fires a projectile toward
//  the player. Appears in the Winter level (Level 4). Cannot be destroyed.
//

import SpriteKit

/// Stationary turret that fires an EnemyProjectile toward the player every
/// `fireCooldown` seconds. The scene receives the projectile through the
/// `onFireProjectile` callback and is responsible for adding it to the node tree.
final class TurretEnemy: EnemyNode {

    /// Segundos entre tiros. Primeiro tiro dispara após 1.5 s.
    private let fireCooldown: TimeInterval = 2.5
    private var fireTimer: TimeInterval
    /// Distância máxima ao jogador para a torreta disparar.
    /// Igual ao alcance real do projétil: velocidade (300) × vida útil (2 s) = 600.
    private let detectionRange: CGFloat = 560

    /// Called when a new projectile is ready. The scene adds it as a child.
    var onFireProjectile: ((EnemyProjectile) -> Void)?

    init() {
        fireTimer = 1.5  // initial delay before the first shot
        let displaySize = CGSize(width: 40, height: 48)
        let tex = SKTexture(imageNamed: "gelinho")
        tex.filteringMode = .nearest
        super.init(
            texture: tex,
            displaySize: displaySize,
            bodySize: CGSize(width: 36, height: 44),
            bodyCenterY: 22,
            anchorY: 0.0,
            isAffectedByGravity: true,   // lands on the ground where placed
            hp: 1,
            isImmortal: true             // cannot be destroyed
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// Decrementa o timer e dispara apenas quando o jogador está ao alcance.
    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead else { return }

        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        guard hypot(dx, dy) <= detectionRange else {
            // Fora de alcance: reseta o timer para não disparar assim que o
            // jogador entrar, dando-lhe o tempo de reação normal.
            fireTimer = max(fireTimer, fireCooldown * 0.5)
            return
        }

        fireTimer -= deltaTime
        guard fireTimer <= 0 else { return }
        fireTimer = fireCooldown

        let dir: CGFloat = dx >= 0 ? 1 : -1
        let spawnPos = CGPoint(x: position.x + dir * 22, y: position.y + 28)
        let projectile = EnemyProjectile(at: spawnPos, direction: dir)
        onFireProjectile?(projectile)
    }
}
