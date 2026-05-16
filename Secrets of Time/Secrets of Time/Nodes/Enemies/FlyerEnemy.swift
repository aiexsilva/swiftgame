import SpriteKit

/// Floating enemy that patrols horizontally at a fixed altitude (no gravity).
/// Uses a placeholder color box until a real sprite is added.
class FlyerEnemy: EnemyNode {

    private let moveSpeed: CGFloat = 170.0
    private let minX: CGFloat
    private let maxX: CGFloat
    private var direction: CGFloat = 1

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        let size = CGSize(width: 44, height: 36)
        super.init(
            texture: EnemyNode.placeholderTexture(size: size, color: .systemPurple),
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
