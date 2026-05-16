import SpriteKit

/// Slow patrolling enemy that cannot be killed. Damage flashes but has no
/// effect. Designed as a hazard the player has to avoid.
class ImmortalEnemy: EnemyNode {

    private let moveSpeed: CGFloat = 28
    private let minX: CGFloat
    private let maxX: CGFloat
    private var direction: CGFloat = 1

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        let size = CGSize(width: 52, height: 52)
        super.init(
            texture: EnemyNode.placeholderTexture(size: size, color: .darkGray),
            displaySize: size,
            bodySize: CGSize(width: 44, height: 48),
            bodyCenterY: 24,
            anchorY: 0,
            isAffectedByGravity: false,
            hp: 1,
            isImmortal: true
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
