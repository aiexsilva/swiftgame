import SpriteKit

/// Enemy that stays idle until the player enters its detection range,
/// then chases the player horizontally.
class ChaserEnemy: EnemyNode {

    private let chaseSpeed: CGFloat = 130
    let detectRange: CGFloat

    init(detectRange: CGFloat = 260) {
        self.detectRange = detectRange
        let size = CGSize(width: 40, height: 48)
        super.init(
            texture: EnemyNode.placeholderTexture(size: size, color: .systemPink),
            displaySize: size,
            bodySize: CGSize(width: 32, height: 44),
            bodyCenterY: 22,
            anchorY: 0,
            isAffectedByGravity: false,
            hp: 4
        )
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func update(deltaTime: TimeInterval, playerPosition: CGPoint) {
        guard !isDead else { return }
        let dx = playerPosition.x - position.x
        let dy = playerPosition.y - position.y
        let dist = hypot(dx, dy)
        guard dist <= detectRange else { return }

        let step = chaseSpeed * CGFloat(deltaTime)
        let move = max(-step, min(step, dx))
        position.x += move
        if move > 0 { xScale = abs(xScale) }
        else if move < 0 { xScale = -abs(xScale) }
    }
}
