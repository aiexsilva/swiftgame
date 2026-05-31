import SpriteKit

/// HUD that displays the player's hit points as small heart icons.
/// Add as child of the camera and call `setHealth(current:max:)` when HP changes.
class HealthHUD: SKNode {

    private let iconSize: CGFloat = 32
    private let spacing: CGFloat = 4
    private var hearts: [SKSpriteNode] = []

    private static let heartTexture: SKTexture = {
        let t = SKTexture(imageNamed: "Heart")
        t.filteringMode = .nearest   // crisp pixel art
        return t
    }()

    func build(maxHitPoints: Int) {
        removeAllChildren()
        hearts.removeAll()
        for i in 0..<maxHitPoints {
            let h = SKSpriteNode(texture: HealthHUD.heartTexture,
                                 size: CGSize(width: iconSize, height: iconSize))
            h.position = CGPoint(x: CGFloat(i) * (iconSize + spacing), y: 0)
            addChild(h)
            hearts.append(h)
        }
    }

    func setHealth(current: Int, max maxHP: Int) {
        if hearts.count != maxHP { build(maxHitPoints: maxHP) }
        for (i, heart) in hearts.enumerated() {
            // Lost HP slots stay visible but turn grey-tinted.
            heart.isHidden = false
            if i < current {
                heart.colorBlendFactor = 0
                heart.alpha = 1.0
            } else {
                heart.color = .black
                heart.colorBlendFactor = 0.75
                heart.alpha = 0.5
            }
        }
    }
}
