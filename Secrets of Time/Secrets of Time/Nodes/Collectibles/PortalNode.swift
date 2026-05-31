import SpriteKit

/// Level-exit portal. Starts locked (dimmed) and becomes interactive after
/// the player has collected enough collectibles. Passing through it (physical
/// contact) when unlocked triggers the scene-level transition.
final class PortalNode: SKSpriteNode {

    var isUnlocked: Bool = false {
        didSet { applyUnlockedAppearance() }
    }

    private let counterLabel = SKLabelNode()

    init(at worldPosition: CGPoint) {
        let displaySize = CGSize(width: 72, height: 110)
        super.init(texture: nil, color: SKColor.systemPurple, size: displaySize)
        position = worldPosition
        name = "portal"
        anchorPoint = CGPoint(x: 0.5, y: 0.0)
        zPosition = 0
        applyUnlockedAppearance()
        setupGlow(size: displaySize)
        setupCounter(size: displaySize)
        setupPhysics(size: displaySize)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupGlow(size: CGSize) {
        // Faint oval glow behind the portal.
        let glow = SKShapeNode(ellipseOf: CGSize(width: size.width * 0.9, height: size.height * 1.05))
        glow.fillColor = SKColor(red: 0.6, green: 0.4, blue: 1.0, alpha: 0.25)
        glow.strokeColor = .clear
        glow.position = CGPoint(x: 0, y: size.height / 2)
        glow.zPosition = -1
        glow.name = "portalGlow"
        addChild(glow)

        // Gentle pulse.
        glow.run(.repeatForever(.sequence([
            .scale(to: 1.1, duration: 0.9),
            .scale(to: 1.0, duration: 0.9)
        ])))
    }

    private func setupPhysics(size: CGSize) {
        let body = SKPhysicsBody(
            rectangleOf: size,
            center: CGPoint(x: 0, y: size.height / 2)
        )
        body.isDynamic = false
        body.affectedByGravity = false
        body.allowsRotation = false
        body.categoryBitMask = PhysicsCategory.portal
        body.collisionBitMask = 0
        body.contactTestBitMask = PhysicsCategory.player
        physicsBody = body
    }

    private func setupCounter(size: CGSize) {
        counterLabel.fontName = "AvenirNext-Bold"
        counterLabel.fontSize = 22
        counterLabel.fontColor = .white
        counterLabel.horizontalAlignmentMode = .center
        counterLabel.verticalAlignmentMode = .bottom
        // Sits just above the portal sprite.
        counterLabel.position = CGPoint(x: 0, y: size.height + 8)
        counterLabel.zPosition = 1
        counterLabel.text = "0 / 0"
        addChild(counterLabel)
    }

    /// Update the "x / N" label shown above the portal.
    func setCounter(collected: Int, required: Int) {
        counterLabel.text = "\(collected) / \(required)"
        counterLabel.fontColor = collected >= required ? .yellow : .white
    }

    private func applyUnlockedAppearance() {
        alpha = isUnlocked ? 1.0 : 0.4
    }
}
