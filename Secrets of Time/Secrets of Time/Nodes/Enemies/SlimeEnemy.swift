import SpriteKit

/// Slime that patrols horizontally between two x bounds on the ground.
class SlimeEnemy: EnemyNode {

    private let moveSpeed: CGFloat = 80.0
    private let minX: CGFloat
    private let maxX: CGFloat
    private var direction: CGFloat = 1

    private static let textures: [SKTexture] = {
        (1...7).map { i in
            let t = SKTexture(imageNamed: "Artboard \(i)")
            t.filteringMode = .nearest
            return t
        }
    }()

    init(minX: CGFloat, maxX: CGFloat) {
        self.minX = min(minX, maxX)
        self.maxX = max(minX, maxX)
        super.init(
            texture: SlimeEnemy.textures.first ?? SKTexture(),
            displaySize: CGSize(width: 48, height: 48),
            bodySize: CGSize(width: 38, height: 28),
            bodyCenterY: 14,
            anchorY: 0.25,            // PNG has padding below the visible slime
            isAffectedByGravity: false,
            hp: 1
        )
        run(.repeatForever(.animate(
            with: SlimeEnemy.textures,
            timePerFrame: 0.12, resize: false, restore: false
        )), withKey: "slimeAnim")
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
