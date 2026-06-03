//
//  JumperEnemy.swift
//  Secrets of Time
//
//  Inimigo saltador do Nível 3 (Outono). Dá dois saltos em frente e dois
//  para trás, repetindo o padrão indefinidamente. Afetado pela gravidade,
//  aterra entre cada salto. Requer 2 ataques para ser eliminado.
//

import SpriteKit

/// Inimigo que alterna entre dois saltos em frente e dois para trás.
class JumperEnemy: EnemyNode {

    private let jumpHorizontalSpeed: CGFloat = 160
    private let jumpImpulse: CGFloat = 38
    private let jumpInterval: TimeInterval = 0.7

    private var goingForward: Bool = true
    private var jumpsInDirection: Int = 0
    private var cooldown: TimeInterval = 0.4

    init() {
        let size = CGSize(width: 40, height: 40)
        let tex = SKTexture(imageNamed: "sapinho")
        tex.filteringMode = .nearest
        super.init(
            texture: tex,
            displaySize: size,
            bodySize: CGSize(width: 32, height: 36),
            bodyCenterY: 18,
            anchorY: 0,
            isAffectedByGravity: true,
            hp: 2
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead, let body = physicsBody else { return }
        cooldown -= deltaTime

        // Only jump when on (or near) the ground and the cooldown has elapsed.
        let grounded = abs(body.velocity.dy) < 1.0
        if cooldown <= 0 && grounded {
            let dir: CGFloat = goingForward ? 1 : -1
            body.velocity = CGVector(dx: dir * jumpHorizontalSpeed, dy: 0)
            body.applyImpulse(CGVector(dx: 0, dy: jumpImpulse))
            xScale = goingForward ? abs(xScale) : -abs(xScale)

            jumpsInDirection += 1
            if jumpsInDirection >= 2 {
                jumpsInDirection = 0
                goingForward.toggle()
            }
            cooldown = jumpInterval
        } else if grounded {
            // Friction-free body: stop horizontal slide between jumps.
            body.velocity = CGVector(dx: 0, dy: body.velocity.dy)
        }
    }
}
